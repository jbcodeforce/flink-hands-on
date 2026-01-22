# -----------------------------------------------------------------------------
# Random ID for unique resource naming
# -----------------------------------------------------------------------------
resource "random_id" "env_display_id" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Flink Compute Pool
# -----------------------------------------------------------------------------
resource "confluent_flink_compute_pool" "flink_pool" {
  count = var.create_compute_pool ? 1 : 0

  display_name = "${var.prefix}-compute-pool-${random_id.env_display_id.hex}"
  cloud        = "AWS"
  region       = var.cloud_region
  max_cfu      = var.flink_max_cfu

  environment {
    id = local.confluent_environment_id
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Data Source: Verify compute pool exists in correct environment (if not creating)
# -----------------------------------------------------------------------------
# Only verify if we're using an existing compute pool (not creating a new one)
data "confluent_flink_compute_pool" "existing_pool" {
  count = var.create_compute_pool ? 0 : (local.flink_compute_pool_id != "" ? 1 : 0)
  id    = local.flink_compute_pool_id

  environment {
    id = local.confluent_environment_id
  }
}

# -----------------------------------------------------------------------------
# Local: Compute pool ID (created or provided)
# -----------------------------------------------------------------------------
# Priority: created pool > cflt_state_path  > variable
locals {
  flink_compute_pool_id_final = var.create_compute_pool ? confluent_flink_compute_pool.flink_pool[0].id : (
    local.flink_compute_pool_id != "" ? local.flink_compute_pool_id  : var.flink_compute_pool_id
  )
}

# -----------------------------------------------------------------------------
# Flink Statements
# DDL and DML statements for transaction enriched table
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# DDL Statement: Create Table
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "ddl" {
  organization {
    id = data.confluent_organization.org.id
  }
  
  environment {
    id = local.confluent_environment_id
  }
  
  compute_pool {
    id = local.flink_compute_pool_id_final
  }
  
  principal {
    id = local.flink_service_account_id
  }
  
  rest_endpoint = data.confluent_flink_region.flink_region.rest_endpoint
  
  # Only include credentials if both key and secret are provided
  dynamic "credentials" {
    for_each = local.flink_api_key != "" && local.flink_api_secret != "" ? [1] : []
    content {
      key    = local.flink_api_key
      secret = local.flink_api_secret
    }
  }
  
  statement      = file(var.ddl_sql_path)
  statement_name = "${var.statement_name_prefix}-ddl"
  
  properties = local.base_properties
  
  # Note: Implicit dependency on compute pool exists via compute_pool.id reference
  # which ensures proper ordering when creating the compute pool
  
  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# DML Statement: Insert Into
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "dml" {
  organization {
    id = data.confluent_organization.org.id
  }
  
  environment {
    id = local.confluent_environment_id
  }
  
  compute_pool {
    id = local.flink_compute_pool_id_final
  }
  
  principal {
    id = local.flink_service_account_id
  }
  
  rest_endpoint = data.confluent_flink_region.flink_region.rest_endpoint
  
  # Only include credentials if both key and secret are provided
  dynamic "credentials" {
    for_each = local.flink_api_key != "" && local.flink_api_secret != "" ? [1] : []
    content {
      key    = local.flink_api_key
      secret = local.flink_api_secret
    }
  }
  
  statement      = file(var.dml_sql_path)
  statement_name = "${var.statement_name_prefix}-dml"
  
  properties = local.dml_properties
  
  # DML statement depends on DDL being created first
  depends_on = [confluent_flink_statement.ddl]
  
  lifecycle {
    prevent_destroy = false
  }
}