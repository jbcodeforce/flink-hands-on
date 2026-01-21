# -----------------------------------------------------------------------------
# Data Sources
# Tableflow Configuration for Transaction Enriched Topic
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Remote State from IaC (Optional)
# -----------------------------------------------------------------------------
# NOTE: If using remote state, the IaC infrastructure must be deployed first.
# If iac_state_path is empty, direct variables will be used instead.
data "terraform_remote_state" "iac" {
  count   = var.iac_state_path != "" ? 1 : 0
  backend = "local"

  config = {
    path = abspath(var.iac_state_path)
  }
}

# -----------------------------------------------------------------------------
# Flink Region Data Source
# -----------------------------------------------------------------------------
data "confluent_flink_region" "flink_region" {
  cloud  = "AWS"
  region = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.cloud_region, "us-east-2") : var.cloud_region
}

# -----------------------------------------------------------------------------
# Organization Data Source
# -----------------------------------------------------------------------------
data "confluent_organization" "org" {}

# -----------------------------------------------------------------------------
# Environment Data Source
# Get environment display name for Flink properties
# -----------------------------------------------------------------------------
data "confluent_environment" "env" {
  id = local.confluent_environment_id
}

# -----------------------------------------------------------------------------
# Kafka Cluster Data Source
# Get cluster display name for Flink properties
# -----------------------------------------------------------------------------
data "confluent_kafka_cluster" "cluster" {
  id = local.kafka_cluster_id
  environment {
    id = local.confluent_environment_id
  }
}

# -----------------------------------------------------------------------------
# Local Values - Get configuration from remote state or variables
# -----------------------------------------------------------------------------
locals {
  # Get values from remote state if available, otherwise use direct variables
  confluent_environment_id = var.iac_state_path != "" ? data.terraform_remote_state.iac[0].outputs.confluent_environment_id : var.confluent_environment_id
  # Try both possible output names: kafka_cluster_id or confluent_kafka_cluster_id
  kafka_cluster_id         = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.kafka_cluster_id, data.terraform_remote_state.iac[0].outputs.confluent_kafka_cluster_id, "") : var.kafka_cluster_id
  s3_bucket_name           = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.s3_bucket_name, "") : var.s3_bucket_name
  tableflow_provider_integration_id = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.tableflow_provider_integration_id, "") : var.tableflow_provider_integration_id
  tableflow_api_key        = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.tableflow_api_key, "") : var.tableflow_api_key
  tableflow_api_secret     = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.tableflow_api_secret, "") : var.tableflow_api_secret
  
  # Flink configuration
  # Only use remote state values if not creating compute pool
  flink_compute_pool_id = var.create_compute_pool ? "" : (var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.flink_compute_pool_id, "") : var.flink_compute_pool_id)
  flink_api_key         = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.flink_api_key, "") : var.flink_api_key
  flink_api_secret      = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.flink_api_secret, "") : var.flink_api_secret
  app_manager_service_account_id = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.app_manager_service_account_id, "") : var.app_manager_service_account_id
  
  # Final compute pool ID: use created pool if creating, otherwise use provided/remote state value
  # This will be set in flink.tf after the compute pool resource is defined
  
  # Base properties for Flink statements
  # Use display names (not IDs) for catalog and database
  base_properties = {
    "sql.current-catalog"  = data.confluent_environment.env.display_name
    "sql.current-database" = data.confluent_kafka_cluster.cluster.display_name
  }
  
  # Parse DML properties file if it exists
  dml_properties = fileexists(var.dml_properties_path) ? merge(
    local.base_properties,
    {
      for line in [
        for l in split("\n", file(var.dml_properties_path)) :
        trimspace(l)
        if length(trimspace(l)) > 0 && !startswith(trimspace(l), "#")
      ] :
      split("=", line)[0] => try(split("=", line)[1], "")
      if length(split("=", line)) == 2
    }
  ) : local.base_properties
  
  # Enable tableflow if provider integration ID exists and enable_tableflow is true
  enable_tableflow = var.enable_tableflow && local.tableflow_provider_integration_id != null && local.tableflow_provider_integration_id != ""
}
