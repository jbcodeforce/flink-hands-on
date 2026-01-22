# -----------------------------------------------------------------------------
# Tableflow Configuration
# Enable Tableflow on transaction enriched topic
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Provider Integration for Tableflow BYOB AWS
# -----------------------------------------------------------------------------
# Create provider integration if tableflow_provider_integration_id is not provided
resource "confluent_provider_integration" "tableflow_aws" {
  count = var.enable_tableflow && local.tableflow_provider_integration_id == "" && local.iam_role_arn != "" ? 1 : 0

  environment {
    id = local.confluent_environment_id
  }

  display_name = "${var.prefix}-tableflow-provider-integration-${random_id.env_display_id.hex}"

  aws {
    customer_role_arn = local.iam_role_arn
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Local to determine final provider integration ID (use provided, remote state, or created)
locals {
  tableflow_provider_integration_id_final = local.tableflow_provider_integration_id != "" ? local.tableflow_provider_integration_id : (var.enable_tableflow && local.iam_role_arn != "" ? try(confluent_provider_integration.tableflow_aws[0].id, "") : "")
}

resource "confluent_catalog_integration" "tx_tf_catalog" {
  environment {
    id = local.confluent_environment_id
  }
  kafka_cluster {
    id = local.kafka_cluster_id
  }
  display_name = "catalog-integration-1"
  aws_glue {
    provider_integration_id = local.tableflow_provider_integration_id_final
  }
  credentials {
    key    = local.tableflow_api_key
    secret = local.tableflow_api_secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Tableflow Enablement for Transaction Enriched Topic
# -----------------------------------------------------------------------------
# Enable Tableflow on the topic to automatically materialize it as an Iceberg table
# This ensures the topic has a schema before Tableflow tries to materialize it
# If the topic is created by Flink DDL statements, ensure those are deployed first

resource "confluent_tableflow_topic" "tx_enriched" {
  count = local.enable_tableflow ? 1 : 0

  environment {
    id = local.confluent_environment_id
  }

  kafka_cluster {
    id = local.kafka_cluster_id
  }

  display_name = var.topic_name
  table_formats = ["ICEBERG"]

  byob_aws {
    bucket_name           = local.s3_bucket_name
    provider_integration_id = local.tableflow_provider_integration_id_final
  }

  credentials {
    key    = local.tableflow_api_key
    secret = local.tableflow_api_secret
  }

  # CRITICAL: Tableflow must be enabled AFTER:
  # 1. DDL statement creates the table (ensures topic has a schema)
  # 2. Provider integration is created (if it's being created)
  depends_on = [
    confluent_flink_statement.ddl,
    confluent_provider_integration.tableflow_aws
  ]

  lifecycle {
    prevent_destroy = false
  }
}
