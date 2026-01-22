# -----------------------------------------------------------------------------
# Outputs
# CDC Postgres to Confluent Cloud Flink
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# AWS Outputs
# -----------------------------------------------------------------------------
output "cloud_region" {
  description = "AWS region where resources are deployed"
  value       = var.cloud_region
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres_db.endpoint
}

output "rds_address" {
  description = "RDS PostgreSQL address (hostname only)"
  value       = aws_db_instance.postgres_db.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres_db.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres_db.db_name
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.postgres_db_sg.id
}

output "rds_allowed_cidr_blocks" {
  description = "All CIDR blocks allowed to access RDS (Confluent Cloud + user IPs)"
  value       = local.all_allowed_cidr_blocks
}

# -----------------------------------------------------------------------------
# Confluent Cloud Outputs (from base infrastructure)
# -----------------------------------------------------------------------------
output "confluent_environment_id" {
  description = "Confluent Cloud environment ID"
  value       = local.environment_id
}

output "confluent_environment_name" {
  description = "Confluent Cloud environment name"
  value       = local.environment_name
}

output "confluent_kafka_cluster_id" {
  description = "Confluent Cloud Kafka cluster ID"
  value       = local.kafka_cluster_id
}

output "confluent_kafka_cluster_name" {
  description = "Confluent Cloud Kafka cluster name"
  value       = local.kafka_cluster_name
}

output "confluent_kafka_cluster_bootstrap_endpoint" {
  description = "Confluent Cloud Kafka cluster bootstrap endpoint"
  value       = data.confluent_kafka_cluster.cdc_cluster.bootstrap_endpoint
}

output "confluent_schema_registry_id" {
  description = "Confluent Cloud Schema Registry cluster ID"
  value       = local.schema_registry_id
}

output "confluent_schema_registry_endpoint" {
  description = "Confluent Cloud Schema Registry REST endpoint"
  value       = local.schema_registry_endpoint
}

output "schema_registry_api_key" {
  description = "Schema Registry API key ID"
  value       = confluent_api_key.app_manager_sr_key.id
  sensitive   = false
}

output "schema_registry_api_secret" {
  description = "Schema Registry API secret"
  value       = confluent_api_key.app_manager_sr_key.secret
  sensitive   = true
}

output "connector_id" {
  description = "Debezium CDC connector ID"
  value       = confluent_connector.postgres_cdc_source.id
}

output "connector_name" {
  description = "Debezium CDC connector name"
  value       = confluent_connector.postgres_cdc_source.config_nonsensitive["name"]
}

output "kafka_topics" {
  description = "Kafka topics created by the CDC connector"
  value = {
    customers    = "${var.prefix}.public.customers"
    transactions = "${var.prefix}.public.transactions"
  }
}

output "schema_subjects" {
  description = "Schema Registry subjects created by the CDC connector"
  value = {
    customers_key    = "${var.prefix}.public.customers-key"
    customers_value  = "${var.prefix}.public.customers-value"
    transactions_key = "${var.prefix}.public.transactions-key"
    transactions_value = "${var.prefix}.public.transactions-value"
  }
}
