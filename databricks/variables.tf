variable "databricks_node_type_id" {
  type    = string
  default = "Standard_DS3_v2"
}

variable "workspace_url" {
  type = string
}

variable "keyvault_resource_id" {
  type = string
}

variable "keyvault_uri" {
  type = string
}

variable "dls_name" {
  type = string
}

variable "sp_tenant_id" {
  type = string
}

variable "sp_client_id" {
  type = string
}

variable "synapse_sql_endpoint" {
  type = string
}
