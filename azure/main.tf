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
  }
}

locals {
  workload = "olympics"
}

resource "azurerm_resource_group" "default" {
  name     = "rg-${local.workload}"
  location = var.location
}

# module "vnet" {
#   source   = "./modules/vnet"
#   workload = local.workload
#   group    = azurerm_resource_group.default.name
#   location = azurerm_resource_group.default.location
# }

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
  source   = "./modules/databricks"
  workload = local.workload
  group    = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  sku = var.dbw_sku
}
