# -----------------------------------------------------------------------------
# Tableflow Configuration
# Enable Tableflow on transaction enriched topic
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Tableflow Enablement for Transaction Enriched Topic
# -----------------------------------------------------------------------------
# Enable Tableflow on the topic to automatically materialize it as an Iceberg table
# This ensures the topic has a schema before Tableflow tries to materialize it
# If the topic is created by Flink DDL statements, ensure those are deployed first

resource "confluent_tableflow_topic" "transaction_enriched" {
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
    provider_integration_id = local.tableflow_provider_integration_id
  }

  credentials {
    key    = local.tableflow_api_key
    secret = local.tableflow_api_secret
  }

  # CRITICAL: Tableflow must be enabled AFTER DDL statement creates the table
  # This ensures the topic has a schema before Tableflow tries to materialize it
  depends_on = [
    confluent_flink_statement.ddl
  ]

  lifecycle {
    prevent_destroy = false
  }
}
