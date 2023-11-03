terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.78.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.45.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.9.0"
    }
  }
}

locals {
  workload = "olympics"
}

resource "azurerm_resource_group" "default" {
  name     = "rg-${local.workload}"
  location = var.location
}

module "aad" {
  source   = "./modules/aad"
  workload = local.workload
}

module "datalake" {
  source   = "./modules/datalake"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  databricks_service_principal_object_id = module.aad.service_principal_object_id
}

module "adf" {
  source   = "./modules/adf"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  datalake_primary_dfs_endpoint = module.datalake.primary_dfs_endpoint
  datalake_primary_access_key   = module.datalake.primary_access_key
}

module "databricks" {
  count    = var.create_databricks == true ? 1 : 0
  source   = "./modules/databricks"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  sku = var.dbw_sku
}

module "synapse" {
  count    = var.create_synapse == true ? 1 : 0
  source   = "./modules/synapse"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  sku_name                             = var.synapse_sku_name
  sql_administrator_login              = var.synapse_sql_administrator_login
  sql_administrator_login_password     = var.synapse_sql_administrator_login_password
  storage_data_lake_gen2_filesystem_id = module.datalake.synapse_transf_filesystem_id
  public_ip_address_to_allow           = var.public_ip_address_to_allow
  datalake_storage_account_id          = module.datalake.storage_account_id
}

module "keyvault" {
  source   = "./modules/keyvault"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  datalake_connection_string               = module.datalake.primary_connection_string
  datalake_access_key                      = module.datalake.primary_access_key
  databricks_sp_secret                     = module.aad.service_credential_secret_value
  synapse_sql_administrator_login          = var.synapse_sql_administrator_login
  synapse_sql_administrator_login_password = var.synapse_sql_administrator_login_password
}

resource "local_file" "databricks_tfvars" {
  content = <<EOF
workspace_url        = "${var.create_databricks == true ? module.databricks[0].workspace_url : ""}"
keyvault_resource_id = "${module.keyvault.id}"
keyvault_uri         = "${module.keyvault.vault_uri}"
dls_name             = "${module.datalake.storage_account_name}"
dls_filesystem_stage = "${module.datalake.databricks_filesystem_stage_name}"
sp_tenant_id         = "${module.aad.tenant_id}"
sp_client_id         = "${module.aad.client_id}"
synapse_sql_endpoint = "${var.create_synapse == true ? module.synapse[0].connectivity_endpoints.sql : ""}"
EOF

  filename = "${path.module}/../databricks/.auto.tfvars"
}
