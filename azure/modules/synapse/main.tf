data "azuread_client_config" "current" {}

resource "azurerm_synapse_workspace" "default" {
  name                                 = "synw-${var.workload}"
  resource_group_name                  = var.group
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_gen2_filesystem_id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = var.sql_administrator_login_password

  managed_resource_group_name   = "rg-${var.workload}-synapse"
  public_network_access_enabled = true

  aad_admin {
    login     = "AzureAD Admin"
    object_id = data.azuread_client_config.current.object_id
    tenant_id = data.azuread_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "pool1" {
  name                      = "pool1"
  synapse_workspace_id      = azurerm_synapse_workspace.default.id
  sku_name                  = var.sku_name
  create_mode               = "Default"
  geo_backup_policy_enabled = false
  storage_account_type      = "LRS"
  collation                 = "SQL_LATIN1_GENERAL_CP1_CI_AS"
}

resource "azurerm_synapse_firewall_rule" "allow_client_ip" {
  name                 = "AllowClientIP"
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  start_ip_address     = var.public_ip_address_to_allow
  end_ip_address       = var.public_ip_address_to_allow
}

# Rule named "AllowAllWindowsAzureIps" with "0.0.0.0" will allow Azure Services to connect.
resource "azurerm_synapse_firewall_rule" "allow_access_to_azure_services" {
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}
