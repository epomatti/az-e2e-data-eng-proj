data "azuread_client_config" "current" {}

resource "azurerm_storage_account" "lake" {
  name                      = "dls${var.workload}"
  resource_group_name       = var.group
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # Hierarchical namespace
  is_hns_enabled = true

  # Networking
  public_network_access_enabled = true
}

resource "azurerm_role_assignment" "adlsv2" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.current.object_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "rawdata"
  storage_account_id = azurerm_storage_account.lake.id

  depends_on = [
    azurerm_role_assignment.adlsv2,
  ]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "transf" {
  name               = "transfdata"
  storage_account_id = azurerm_storage_account.lake.id

  depends_on = [
    azurerm_role_assignment.adlsv2,
  ]
}

# Allow Databricks AAD SP to connect
resource "azurerm_role_assignment" "databricks" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.databricks_service_principal_object_id
}
