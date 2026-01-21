# -----------------------------------------------------------------------------
# Service Accounts, API Keys, and ACLs
# CDC Postgres to Confluent Cloud Flink
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Data Sources for Existing Service Accounts
# -----------------------------------------------------------------------------

# Fetch existing app manager service account if ID is provided
data "confluent_service_account" "existing_app_manager" {
  count = var.app_manager_sa_id != "" ? 1 : 0
  id    = var.app_manager_sa_id
}

# Fetch existing connectors service account if ID is provided
data "confluent_service_account" "existing_connectors" {
  count = var.connectors_sa_id != "" ? 1 : 0
  id    = var.connectors_sa_id
}

# -----------------------------------------------------------------------------
# Service Accounts (Create if not provided)
# -----------------------------------------------------------------------------

# App Manager - Full environment admin for cluster management
resource "confluent_service_account" "app_manager" {
  count        = var.app_manager_sa_id == "" ? 1 : 0
  display_name = "${var.prefix}-app-manager-${random_id.env_display_id.hex}"
  description  = "Service account for managing CDC resources"

  lifecycle {
    prevent_destroy = false
  }
}

# Connectors - For CDC connectors
resource "confluent_service_account" "connectors" {
  count        = var.connectors_sa_id == "" ? 1 : 0
  display_name = "${var.prefix}-connectors-${random_id.env_display_id.hex}"
  description  = "Service account for CDC connectors"

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Locals for Service Account References
# -----------------------------------------------------------------------------

locals {
  # Use existing service account if provided, otherwise use created one
  app_manager_sa = var.app_manager_sa_id != "" ? data.confluent_service_account.existing_app_manager[0] : confluent_service_account.app_manager[0]
  connectors_sa   = var.connectors_sa_id != "" ? data.confluent_service_account.existing_connectors[0] : confluent_service_account.connectors[0]
}

# -----------------------------------------------------------------------------
# Role Bindings
# -----------------------------------------------------------------------------

# App Manager - Environment Admin
resource "confluent_role_binding" "app_manager_env_admin" {
  principal   = "User:${local.app_manager_sa.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cdc_env.resource_name

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# API Keys
# -----------------------------------------------------------------------------

# App Manager - Kafka API Key
resource "confluent_api_key" "app_manager_kafka_key" {
  display_name = "${var.prefix}-app-manager-kafka-key"
  description  = "Kafka API Key for app-manager service account"

  owner {
    id          = local.app_manager_sa.id
    api_version = local.app_manager_sa.api_version
    kind        = local.app_manager_sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cdc_cluster.id
    api_version = confluent_kafka_cluster.cdc_cluster.api_version
    kind        = confluent_kafka_cluster.cdc_cluster.kind

    environment {
      id = confluent_environment.cdc_env.id
    }
  }

  depends_on = [
    confluent_role_binding.app_manager_env_admin
  ]

  lifecycle {
    prevent_destroy = false
  }
}

# App Manager - Schema Registry API Key
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
      id = confluent_environment.cdc_env.id
    }
  }

  depends_on = [
    confluent_role_binding.app_manager_env_admin
  ]

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# ACLs for Connectors Service Account
# -----------------------------------------------------------------------------

resource "confluent_kafka_acl" "connectors_create_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cdc_cluster.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"

  rest_endpoint = confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app_manager_kafka_key.id
    secret = confluent_api_key.app_manager_kafka_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_write_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cdc_cluster.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"

  rest_endpoint = confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app_manager_kafka_key.id
    secret = confluent_api_key.app_manager_kafka_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_read_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cdc_cluster.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"

  rest_endpoint = confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app_manager_kafka_key.id
    secret = confluent_api_key.app_manager_kafka_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_describe_cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.cdc_cluster.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"

  rest_endpoint = confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app_manager_kafka_key.id
    secret = confluent_api_key.app_manager_kafka_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_read_group" {
  kafka_cluster {
    id = confluent_kafka_cluster.cdc_cluster.id
  }

  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${local.connectors_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"

  rest_endpoint = confluent_kafka_cluster.cdc_cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app_manager_kafka_key.id
    secret = confluent_api_key.app_manager_kafka_key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}
