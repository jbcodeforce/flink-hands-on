# -----------------------------------------------------------------------------
# Outputs
# Tableflow Configuration for Transaction Enriched Topic
# -----------------------------------------------------------------------------

output "tableflow_enabled" {
  description = "Whether Tableflow is enabled on the topic"
  value       = local.enable_tableflow
}

output "tableflow_topic_name" {
  description = "Tableflow-enabled topic name"
  value       = local.enable_tableflow ? try(confluent_tableflow_topic.transaction_enriched[0].display_name, null) : null
}

output "tableflow_topic_id" {
  description = "Tableflow topic ID"
  value       = local.enable_tableflow ? try(confluent_tableflow_topic.transaction_enriched[0].id, null) : null
}

output "s3_bucket_name" {
  description = "S3 bucket name used for Iceberg storage"
  value       = local.s3_bucket_name
}

output "tableflow_provider_integration_id" {
  description = "Tableflow provider integration ID"
  value       = local.tableflow_provider_integration_id
}

# -----------------------------------------------------------------------------
# Flink Statement Outputs
# -----------------------------------------------------------------------------
output "ddl_statement_id" {
  description = "DDL Flink statement ID"
  value       = confluent_flink_statement.ddl.id
}

output "ddl_statement_name" {
  description = "DDL Flink statement name"
  value       = confluent_flink_statement.ddl.statement_name
}

output "dml_statement_id" {
  description = "DML Flink statement ID"
  value       = confluent_flink_statement.dml.id
}

output "dml_statement_name" {
  description = "DML Flink statement name"
  value       = confluent_flink_statement.dml.statement_name
}

# -----------------------------------------------------------------------------
# Flink Compute Pool Outputs
# -----------------------------------------------------------------------------
output "flink_compute_pool_id" {
  description = "Flink compute pool ID (created or provided)"
  value       = local.flink_compute_pool_id_final
}

output "flink_compute_pool_name" {
  description = "Flink compute pool display name (if created)"
  value       = var.create_compute_pool ? confluent_flink_compute_pool.flink_pool[0].display_name : null
}
