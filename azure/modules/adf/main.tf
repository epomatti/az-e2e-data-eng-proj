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

# Stage 1
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

resource "azapi_resource" "unzip_sink" {
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

resource "azapi_resource" "excel_raw_source" {
  type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  name      = "TokyoExcelRaw"
  parent_id = azurerm_data_factory.default.id
  body = jsonencode({
    "properties" : {
      "type" : "Excel",
      "linkedServiceName" : {
        "referenceName" : "${local.data_lake_name}",
        "type" : "LinkedServiceReference"
      },
      "schema" : [],
      "typeProperties" : {
        "location" : {
          "type" : "AzureBlobFSLocation",
          "fileName" : "*.xlsx",
          "fileSystem" : "raw-data"
        },
        "sheetIndex": 0,
        "firstRowAsHeader" : true
      }
    }
  })
}

resource "azapi_resource" "csv_sink" {
  type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  name      = "TokyoCSVSink"
  parent_id = azurerm_data_factory.default.id
  body = jsonencode({
    "properties" : {
      "linkedServiceName" : {
        "referenceName" : "${local.data_lake_name}",
        "type" : "LinkedServiceReference"
      },
      "annotations" : [],
      "type" : "DelimitedText",
      "typeProperties" : {
        "location" : {
          "type" : "AzureBlobFSLocation",
          "fileSystem" : "staged-data"
        },
        "columnDelimiter" : ",",
        "escapeChar" : "\\",
        "firstRowAsHeader" : false,
        "quoteChar" : "\"",
      },
      "schema" : []
    }
  })
}

resource "azapi_resource" "prepare" {
  type      = "Microsoft.DataFactory/factories/pipelines@2018-06-01"
  name      = "PrepareForDatabricks"
  parent_id = azurerm_data_factory.default.id
  body = jsonencode({
    "properties" : {
      "activities" : [
        {
          "name" : "Unzip",
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
              "referenceName" : "${azapi_resource.unzip_sink.name}",
              "type" : "DatasetReference"
            }
          ]
        },
        {
          "name" : "Convert Excel to CSV",
          "type" : "Copy",
          "dependsOn" : [
            {
              "activity" : "Unzip",
              "dependencyConditions" : [
                "Succeeded"
              ]
            }
          ],
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
              "type" : "ExcelSource",
              "storeSettings" : {
                "type" : "AzureBlobFSReadSettings",
                "recursive" : false,
              }
            },
            "sink" : {
              "type" : "DelimitedTextSink",
              "storeSettings" : {
                "type" : "AzureBlobFSWriteSettings"
              },
              "formatSettings" : {
                "type" : "DelimitedTextWriteSettings",
                "quoteAllText" : true,
                "fileExtension" : ".csv"
              }
            },
            "enableStaging" : false,
            "translator" : {
              "type" : "TabularTranslator",
              "typeConversion" : true,
              "typeConversionSettings" : {
                "allowDataTruncation" : true,
                "treatBooleanAsNumber" : false
              }
            }
          },
          "inputs" : [
            {
              "referenceName" : "${azapi_resource.excel_raw_source.name}",
              "type" : "DatasetReference"
            }
          ],
          "outputs" : [
            {
              "referenceName" : "${azapi_resource.csv_sink.name}",
              "type" : "DatasetReference"
            }
          ]
        }
      ],
      "annotations" : []
    }
  })
}
