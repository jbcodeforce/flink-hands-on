# -----------------------------------------------------------------------------
# Service Accounts, API Keys, and ACLs
# CDC Postgres to Confluent Cloud Flink
# Reuses base infrastructure service account and creates connector-specific service account
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Service Accounts
# -----------------------------------------------------------------------------

# Reuse the base service account from infrastructure for app manager operations
# This service account already has EnvironmentAdmin role from base infrastructure
locals {
  app_manager_sa = data.confluent_service_account.base_sa
}

# Connectors - For CDC connectors (create new if not provided)
data "confluent_service_account" "existing_connectors" {
  count = var.connectors_sa_id != "" ? 1 : 0
  id    = var.connectors_sa_id
}

resource "confluent_service_account" "connectors" {
  count        = var.connectors_sa_id == "" ? 1 : 0
  display_name = "${var.prefix}-connectors-${random_id.env_display_id.hex}"
  description  = "Service account for CDC connectors"

  lifecycle {
    prevent_destroy = false
  }
}

locals {
  connectors_sa = var.connectors_sa_id != "" ? data.confluent_service_account.existing_connectors[0] : confluent_service_account.connectors[0]
}

# -----------------------------------------------------------------------------
# Role Bindings
# -----------------------------------------------------------------------------

# Note: App Manager role binding is already created in base infrastructure
# The base service account already has EnvironmentAdmin role

# -----------------------------------------------------------------------------
# API Keys
# -----------------------------------------------------------------------------

# Reuse Kafka API Key from base infrastructure
locals {
  app_manager_kafka_key_id     = local.kafka_api_key_id
  app_manager_kafka_key_secret = local.kafka_api_key_secret
}

# App Manager - Schema Registry API Key
# Create a new Schema Registry API key for this module's operations
resource "confluent_api_key" "app_manager_sr_key" {
  display_name = "${var.prefix}-app-manager-sr-key"
  description  = "Schema Registry API Key for app-manager service account"

  owner {
    id          = local.app_manager_sa.id
    api_version = local.app_manager_sa.api_version
    kind        = local.app_manager_sa.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.cdc_sr.id
    api_version = data.confluent_schema_registry_cluster.cdc_sr.api_version
    kind        = data.confluent_schema_registry_cluster.cdc_sr.kind

    environment {
      id = local.environment_id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# ACLs for Connectors Service Account
# -----------------------------------------------------------------------------

resource "confluent_kafka_acl" "connectors_create_topic" {
  kafka_cluster {
    id = local.kafka_cluster_id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"

  rest_endpoint = data.confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = local.app_manager_kafka_key_id
    secret = local.app_manager_kafka_key_secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_write_topic" {
  kafka_cluster {
    id = local.kafka_cluster_id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"

  rest_endpoint = data.confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = local.app_manager_kafka_key_id
    secret = local.app_manager_kafka_key_secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_read_topic" {
  kafka_cluster {
    id = local.kafka_cluster_id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"

  rest_endpoint = data.confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = local.app_manager_kafka_key_id
    secret = local.app_manager_kafka_key_secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_describe_cluster" {
  kafka_cluster {
    id = local.kafka_cluster_id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"

  rest_endpoint = data.confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = local.app_manager_kafka_key_id
    secret = local.app_manager_kafka_key_secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_read_group" {
  kafka_cluster {
    id = local.kafka_cluster_id
  }

  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"

  rest_endpoint = data.confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = local.app_manager_kafka_key_id
    secret = local.app_manager_kafka_key_secret
  }

  lifecycle {
    prevent_destroy = false
  }
}
