# -----------------------------------------------------------------------------
# Confluent Cloud Infrastructure
# Postgres -> CDC in Confluent Cloud
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
resource "confluent_environment" "cdc_env" {
  display_name = "${var.prefix}-environment-${random_id.env_display_id.hex}"

  stream_governance {
    package = "ADVANCED"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Schema Registry (auto-provisioned with ADVANCED governance)
# -----------------------------------------------------------------------------
data "confluent_schema_registry_cluster" "cdc_sr" {
  environment {
    id = confluent_environment.cdc_env.id
  }

  depends_on = [
    confluent_kafka_cluster.cdc_cluster
  ]
}

# -----------------------------------------------------------------------------
# Kafka Cluster
# -----------------------------------------------------------------------------
resource "confluent_kafka_cluster" "cdc_cluster" {
  display_name = "${var.prefix}-cluster-${random_id.env_display_id.hex}"
  availability = var.cc_availability
  cloud        = "AWS"
  region       = var.cloud_region

  standard {}

  environment {
    id = confluent_environment.cdc_env.id
  }

  lifecycle {
    prevent_destroy = false
  }
}
