# -----------------------------------------------------------------------------
# Data Sources
# Reference Confluent Cloud Infrastructure from Base Terraform State
# -----------------------------------------------------------------------------

# Reference the terraform state from the base Confluent Cloud infrastructure
data "terraform_remote_state" "confluent_infrastructure" {
  backend = "local"

  config = {
    path = "${path.module}/../../1-confluent-cloud-infrastructure/terraform.tfstate"
  }
}

# -----------------------------------------------------------------------------
# Confluent Cloud Resources from Remote State
# -----------------------------------------------------------------------------
locals {
  # Environment
  environment_id         = data.terraform_remote_state.confluent_infrastructure.outputs.confluent_environment_id
  environment_name       = data.terraform_remote_state.confluent_infrastructure.outputs.confluent_environment_name
  environment_resource_name = "env:${data.terraform_remote_state.confluent_infrastructure.outputs.confluent_environment_id}"

  # Kafka Cluster
  kafka_cluster_id       = data.terraform_remote_state.confluent_infrastructure.outputs.kafka_cluster_id
  kafka_cluster_name     = data.terraform_remote_state.confluent_infrastructure.outputs.kafka_cluster_name

  # Schema Registry
  schema_registry_id     = data.terraform_remote_state.confluent_infrastructure.outputs.schema_registry_id
  schema_registry_endpoint = data.terraform_remote_state.confluent_infrastructure.outputs.schema_registry_endpoint

  # Service Account (from base infrastructure)
  service_account_id    = data.terraform_remote_state.confluent_infrastructure.outputs.service_account_id
  service_account_name   = data.terraform_remote_state.confluent_infrastructure.outputs.service_account_name

  # Kafka API Keys (from base infrastructure)
  kafka_api_key_id       = data.terraform_remote_state.confluent_infrastructure.outputs.kafka_api_key_id
  kafka_api_key_secret   = data.terraform_remote_state.confluent_infrastructure.outputs.kafka_api_key_secret

  # Cloud Region
  cloud_region          = data.terraform_remote_state.confluent_infrastructure.outputs.cloud_region
}

# Data source for environment (needed for some resource references)
data "confluent_environment" "cdc_env" {
  id = local.environment_id
}

# Data source for Kafka cluster (needed for connector and ACL references)
data "confluent_kafka_cluster" "cdc_cluster" {
  id = local.kafka_cluster_id

  environment {
    id = local.environment_id
  }
}

# Data source for Schema Registry (needed for connector references)
data "confluent_schema_registry_cluster" "cdc_sr" {
  id = local.schema_registry_id

  environment {
    id = local.environment_id
  }
}

# Data source for service account (needed for connector and ACL references)
data "confluent_service_account" "base_sa" {
  id = local.service_account_id
}
