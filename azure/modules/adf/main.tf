resource "azurerm_data_factory" "default" {
  name                   = "adf-${var.workload}-sandbox"
  location               = var.location
  resource_group_name    = var.group
  public_network_enabled = true
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "lake" {
  name                = "Lake"
  data_factory_id     = azurerm_data_factory.default.id
  url                 = var.datalake_primary_dfs_endpoint
  storage_account_key = var.datalake_primary_access_key
}

# resource "azapi_resource" "symbolicname" {
#   type = "Microsoft.DataFactory/factories/datasets@2018-06-01"
#   name = "string"
#   parent_id = azurerm_data_factory.default.id
#   body = jsonencode({
#     properties = {
#       annotations = [ object ]
#       description = "string"
#       folder = {
#         name = "string"
#       }
#       linkedServiceName = {
#         parameters = {}
#         referenceName = "string"
#         type = "LinkedServiceReference"
#       }
#       parameters = {}
#       type = "string"
#       // For remaining properties, see Dataset objects
#     }
#   })
# }
