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
  value       = local.enable_tableflow ? try(confluent_tableflow_topic.tx_enriched[0].display_name, null) : null
}

output "tableflow_topic_id" {
  description = "Tableflow topic ID"
  value       = local.enable_tableflow ? try(confluent_tableflow_topic.tx_enriched[0].id, null) : null
}

output "s3_bucket_name" {
  description = "S3 bucket name used for Iceberg storage"
  value       = local.s3_bucket_name
}

output "tableflow_provider_integration_id" {
  description = "Tableflow provider integration ID (provided, from remote state, or created)"
  value       = local.tableflow_provider_integration_id_final
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
# AWS Glue Catalog Outputs
# -----------------------------------------------------------------------------
output "glue_database_name" {
  description = "Glue catalog database name for Iceberg tables"
  value       = aws_glue_catalog_database.tx_iceberg_db.name
}

output "glue_database_arn" {
  description = "Glue catalog database ARN"
  value       = aws_glue_catalog_database.tx_iceberg_db.arn
}

# -----------------------------------------------------------------------------
# AWS Athena Outputs
# -----------------------------------------------------------------------------
output "athena_workgroup_name" {
  description = "Athena workgroup name for querying Iceberg tables"
  value       = aws_athena_workgroup.tx_workgroup.name
}

output "athena_workgroup_arn" {
  description = "Athena workgroup ARN"
  value       = aws_athena_workgroup.tx_workgroup.arn
}

output "athena_query_results_location" {
  description = "S3 location for Athena query results"
  value       = "s3://${local.s3_bucket_name}/athena-results/"
}

