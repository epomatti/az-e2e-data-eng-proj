terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

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

locals {
  data_lake_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.lake.name
}

resource "azapi_resource" "zip_source" {
  type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  name      = "TokyoZipSourceDataset"
  parent_id = azurerm_data_factory.default.id
  body = jsonencode({
    "properties" : {
      "linkedServiceName" : {
        "referenceName" : "${local.data_lake_name}",
        "type" : "LinkedServiceReference"
      },
      "annotations" : [],
      "type" : "Binary",
      "typeProperties" : {
        "location" : {
          "type" : "AzureBlobFSLocation",
          "fileName" : "tokyo2011.zip",
          "fileSystem" : "raw-source"
        },
        "compression" : {
          "type" : "ZipDeflate"
        }
      }
    }
  })
}

resource "azapi_resource" "unzip" {
  type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  name      = "TokyoUnzipDataset"
  parent_id = azurerm_data_factory.default.id
  body = jsonencode({
    "properties" : {
      "linkedServiceName" : {
        "referenceName" : "${local.data_lake_name}",
        "type" : "LinkedServiceReference"
      },
      "annotations" : [],
      "type" : "Binary",
      "typeProperties" : {
        "location" : {
          "type" : "AzureBlobFSLocation",
          "fileSystem" : "raw-data"
        },
      },
      "schema" : []
    }
  })
}

resource "azapi_resource" "pipeline_unzip" {
  type      = "Microsoft.DataFactory/factories/pipelines@2018-06-01"
  name      = "UnzipTokio"
  parent_id = azurerm_data_factory.default.id
  body = jsonencode({
    "properties" : {
      "activities" : [
        {
          "name" : "Copy data1",
          "type" : "Copy",
          "dependsOn" : [],
          "policy" : {
            "timeout" : "0.12:00:00",
            "retry" : 0,
            "retryIntervalInSeconds" : 30,
            "secureOutput" : false,
            "secureInput" : false
          },
          "userProperties" : [],
          "typeProperties" : {
            "source" : {
              "type" : "BinarySource",
              "storeSettings" : {
                "type" : "AzureBlobFSReadSettings",
                "recursive" : true
              },
              "formatSettings" : {
                "type" : "BinaryReadSettings",
                "compressionProperties" : {
                  "type" : "ZipDeflateReadSettings",
                  "preserveZipFileNameAsFolder" : false,
                }
              }
            },
            "sink" : {
              "type" : "BinarySink",
              "storeSettings" : {
                "type" : "AzureBlobFSWriteSettings",
                "copyBehavior" : "PreserveHierarchy"
              }
            },
            "enableStaging" : false
          },
          "inputs" : [
            {
              "referenceName" : "${azapi_resource.zip_source.name}",
              "type" : "DatasetReference"
            }
          ],
          "outputs" : [
            {
              "referenceName" : "${azapi_resource.unzip.name}",
              "type" : "DatasetReference"
            }
          ]
        }
      ],
      "annotations" : []
    }
  })
}

# resource "azapi_resource" "zip_source" {
#   type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
#   name      = "TokyoZipSourceDataset"
#   parent_id = azurerm_data_factory.default.id
#   body = jsonencode({
#     "properties" : {
#       "linkedServiceName" : {
#         "referenceName" : "${local.data_lake_name}",
#         "type" : "LinkedServiceReference"
#       },
#       "annotations" : [],
#       "type" : "Binary",
#       "typeProperties" : {
#         "location" : {
#           "type" : "AzureBlobFSLocation",
#           "fileName" : "tokyo2011.zip",
#           "fileSystem" : "raw-data"
#         },
#         "compression" : {
#           "type" : "ZipDeflate"
#         }
#       }
#     }
#   })
# }

# "properties": {
#         "type": "Excel",
#         "linkedServiceName": {
#             "referenceName": "<Azure Blob Storage linked service name>",
#             "type": "LinkedServiceReference"
#         },
#         "schema": [ < physical schema, optional, retrievable during authoring > ],
#         "typeProperties": {
#             "location": {
#                 "type": "AzureBlobStorageLocation",
#                 "container": "containername",
#                 "folderPath": "folder/subfolder",
#             },
#             "sheetName": "MyWorksheet",
#             "range": "A3:H5",
#             "firstRowAsHeader": true
#         }
#     }