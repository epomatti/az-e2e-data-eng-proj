resource "azurerm_databricks_workspace" "default" {
  name                          = "dbw-${var.workload}"
  resource_group_name           = var.group
  location                      = var.location
  managed_resource_group_name   = "rg-${var.workload}-databricks"
  sku                           = var.sku
  public_network_access_enabled = true
}
