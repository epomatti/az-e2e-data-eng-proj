variable "group" {
  type = string
}

variable "location" {
  type = string
}

variable "workload" {
  type = string
}

variable "datalake_primary_dfs_endpoint" {
  type = string
}

variable "datalake_primary_access_key" {
  type      = string
  sensitive = true
}
