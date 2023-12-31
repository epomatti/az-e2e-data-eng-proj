terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.29.0"
    }
  }
}

provider "databricks" {
  host = var.workspace_url
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = "Shared Autoscaling"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = var.databricks_node_type_id
  autotermination_minutes = 60

  autoscale {
    min_workers = 1
    max_workers = 5
  }

  spark_env_vars = {
    DLS_NAME             = "${var.dls_name}"
    DLS_FILESYSTEM_STAGE = "${var.dls_filesystem_stage}"
    SP_TENANT_ID         = "${var.sp_tenant_id}"
    SP_CLIENT_ID         = "${var.sp_client_id}"
    SYNAPSE_SQL_ENDPOINT = "${var.synapse_sql_endpoint}"
  }
}

# This was just for Pandas testing - not really required for this example
resource "databricks_library" "fsspec" {
  cluster_id = databricks_cluster.shared_autoscaling.id
  pypi {
    package = "fsspec"
  }
}

# This was just for Pandas testing - not really required for this example
resource "databricks_library" "adlfs" {
  cluster_id = databricks_cluster.shared_autoscaling.id
  pypi {
    package = "adlfs"
  }
}

resource "databricks_secret_scope" "kv" {
  name = "keyvault-managed"

  keyvault_metadata {
    resource_id = var.keyvault_resource_id
    dns_name    = var.keyvault_uri
  }
}

data "databricks_current_user" "me" {
}

resource "databricks_notebook" "tokyo" {
  source = "${path.module}/notebooks/tokyo-olympic.ipynb"
  path   = "${data.databricks_current_user.me.home}/tokyo-olympic"
}
