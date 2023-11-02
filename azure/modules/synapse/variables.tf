variable "workload" {
  type = string
}

variable "group" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "storage_data_lake_gen2_filesystem_id" {
  type = string
}

variable "sql_administrator_login" {
  type = string
}

variable "sql_administrator_login_password" {
  type      = string
  sensitive = true
}

variable "public_ip_address_to_allow" {
  type = string
}

variable "datalake_storage_account_id" {
  type = string
}
