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

data "terraform_remote_state" "cflt_state" {
  count   = var.iac_state_path != "" ? 1 : 0
  backend = "local"

  config = {
    path = abspath(var.cflt_state_path)
  }
}


# -----------------------------------------------------------------------------
# Flink Region Data Source
# -----------------------------------------------------------------------------
data "confluent_flink_region" "flink_region" {
  cloud  = "AWS"
  region = var.cflt_state_path != "" ? try(data.terraform_remote_state.cflt_state[0].outputs.cloud_region, "us-east-2") : var.cloud_region
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
  confluent_environment_id = var.cflt_state_path != "" ? data.terraform_remote_state.cflt_state[0].outputs.confluent_environment_id : var.confluent_environment_id
  # Try both possible output names: kafka_cluster_id or confluent_kafka_cluster_id
  kafka_cluster_id         = var.cflt_state_path != "" ? try(data.terraform_remote_state.cflt_state[0].outputs.kafka_cluster_id, data.terraform_remote_state.cflt_state[0].outputs.confluent_kafka_cluster_id, "") : var.kafka_cluster_id
  # S3 bucket name - check both state paths and variable
  # Priority: variable >  iac_state_path
  s3_bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : (
      var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.s3_bucket_name, "") : ""
    )
  
  
  # Tableflow provider integration ID - use provided or remote state
  # If not provided, it will be created by confluent_provider_integration.tableflow_aws resource
  # The final ID (including created resource) is determined in tableflow.tf
  tableflow_provider_integration_id = var.tableflow_provider_integration_id != "" ? var.tableflow_provider_integration_id : (var.cflt_state_path != "" ? try(data.terraform_remote_state.cflt_state[0].outputs.tableflow_provider_integration_id, "") : "")

  # Flink configuration
  # Only use remote state values if not creating compute pool
  flink_compute_pool_id = var.cflt_state_path != ""  ? try(data.terraform_remote_state.cflt_state[0].outputs.flink_compute_pool_id, "") : var.flink_compute_pool_id
  
  # Flink API key - check both output name variations and variable
  # Output names: flink_api_key_id/flink_api_key_secret (from 1-confluent-cloud-infrastructure)
  flink_api_key_from_state = var.cflt_state_path != "" ? try(
    data.terraform_remote_state.cflt_state[0].outputs.flink_api_key_id,
    data.terraform_remote_state.cflt_state[0].outputs.flink_api_key,
    ""
  ) : ""
  flink_api_key = var.flink_api_key != "" ? var.flink_api_key : local.flink_api_key_from_state
  
  flink_api_secret_from_state = var.cflt_state_path != "" ? try(
    data.terraform_remote_state.cflt_state[0].outputs.flink_api_key_secret,
    data.terraform_remote_state.cflt_state[0].outputs.flink_api_secret,
    ""
  ) : ""
  flink_api_secret = var.flink_api_secret != "" ? var.flink_api_secret : local.flink_api_secret_from_state
  
  # Tableflow API key - Priority: variable > remote state > confluent_cloud_api_key
  # Tableflow requires a specific API key scoped to "tableflow" managed resource
  tableflow_api_key_from_state = var.cflt_state_path != "" ? try(
    data.terraform_remote_state.cflt_state[0].outputs.tableflow_api_key,
    ""
  ) : ""
  tableflow_api_key = var.tableflow_api_key != "" ? var.tableflow_api_key : (
    local.tableflow_api_key_from_state != "" ? local.tableflow_api_key_from_state : var.confluent_cloud_api_key
  )
  
  tableflow_api_secret_from_state = var.cflt_state_path != "" ? try(
    data.terraform_remote_state.cflt_state[0].outputs.tableflow_api_secret,
    ""
  ) : ""
  tableflow_api_secret = var.tableflow_api_secret != "" ? var.tableflow_api_secret : (
    local.tableflow_api_secret_from_state != "" ? local.tableflow_api_secret_from_state : var.confluent_cloud_api_secret
  )
  
  # Support both new flink_service_account_id and legacy app_manager_service_account_id
  # Priority: flink_service_account_id > app_manager_service_account_id > remote state
  # Get service account ID from remote state (output is service_account_id)
  flink_service_account_id_from_state = var.cflt_state_path != "" ? try(
    data.terraform_remote_state.cflt_state[0].outputs.service_account_id,
    ""
  ) : ""
  
  flink_service_account_id = coalesce(
    var.flink_service_account_id != "" ? var.flink_service_account_id : null,
    var.app_manager_service_account_id != "" ? var.app_manager_service_account_id : null,
    local.flink_service_account_id_from_state != "" ? local.flink_service_account_id_from_state : null
  )
  
  # Legacy variable for backward compatibility
  app_manager_service_account_id = local.flink_service_account_id
  
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
  
  # Enable tableflow if enable_tableflow is true and we have either:
  # - A provider integration ID from variable/remote state, OR
  # - An IAM role ARN to create the provider integration
  enable_tableflow = var.enable_tableflow && (local.tableflow_provider_integration_id != "" || local.iam_role_arn != "")
  
  # IAM role and policy ARNs - use remote state if available, otherwise use variables
  # Single IAM role used for both Glue and Athena
  # Priority: remote state > variable
  iam_role_arn_from_state = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.iam_role_arn, "") : ""
  iam_role_arn = local.iam_role_arn_from_state != "" ? local.iam_role_arn_from_state : var.iam_role_arn
  
  glue_s3_policy_arn = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.glue_s3_policy_arn, "") : var.iam_policy_name
  athena_access_policy_arn = var.iac_state_path != "" ? try(data.terraform_remote_state.iac[0].outputs.athena_access_policy_arn, "") : var.iam_policy_name
}
