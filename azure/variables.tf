### Project ###
variable "location" {
  type    = string
  default = "eastus"
}

variable "public_ip_address_to_allow" {
  type = string
}

### Databricks ###
variable "dbw_sku" {
  type = string
}

### Synapse ###
variable "synapse_sku_name" {
  type = string
}

variable "synapse_sql_administrator_login" {
  type = string
}

variable "synapse_sql_administrator_login_password" {
  type      = string
  sensitive = true
}
