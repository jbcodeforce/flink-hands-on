# -----------------------------------------------------------------------------
# Variables Configuration
# Tableflow Configuration for Transaction Enriched Topic
# -----------------------------------------------------------------------------

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (can be set via CONFLUENT_CLOUD_API_KEY env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret (can be set via CONFLUENT_CLOUD_API_SECRET env var)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "iac_state_path" {
  description = "Path to the IaC terraform state file (relative to this terraform directory). Set to empty string if not using remote state."
  type        = string
  default     = ""
}

variable "topic_name" {
  description = "Name of the Kafka topic to enable Tableflow on (transaction enriched topic)"
  type        = string
  default     = "transaction_enriched"
}

variable "enable_tableflow" {
  description = "Enable Tableflow on the topic"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Direct Configuration (if not using remote state)
# -----------------------------------------------------------------------------
variable "confluent_environment_id" {
  description = "Confluent Cloud environment ID (required if not using remote state)"
  type        = string
  default     = ""
}

variable "kafka_cluster_id" {
  description = "Kafka cluster ID (required if not using remote state)"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Iceberg storage (required if not using remote state)"
  type        = string
  default     = ""
}

variable "tableflow_provider_integration_id" {
  description = "Confluent provider integration ID for Tableflow BYOB AWS storage (required if not using remote state)"
  type        = string
  default     = ""
}

variable "tableflow_api_key" {
  description = "Tableflow API Key ID (required if not using remote state)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tableflow_api_secret" {
  description = "Tableflow API Secret (required if not using remote state)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Flink Configuration
# -----------------------------------------------------------------------------
variable "flink_compute_pool_id" {
  description = "Flink compute pool ID (required if not using remote state)"
  type        = string
  default     = ""
}

variable "flink_api_key" {
  description = "Flink API Key ID (required if not using remote state)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "flink_api_secret" {
  description = "Flink API Secret (required if not using remote state)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_manager_service_account_id" {
  description = "App Manager service account ID for Flink statements (required if not using remote state)"
  type        = string
  default     = ""
}

variable "cloud_region" {
  description = "AWS region for Flink deployment (required if not using remote state)"
  type        = string
  default     = "us-east-2"
}

variable "statement_name_prefix" {
  description = "Prefix for Flink statement names"
  type        = string
  default     = "tx-enriched"
}

variable "ddl_sql_path" {
  description = "Path to DDL SQL file (relative to terraform directory)"
  type        = string
  default     = "../flink-sql/dim_enriched_tx/sql-scripts/ddl.txp_dim_enriched_tx.sql"
}

variable "dml_sql_path" {
  description = "Path to DML SQL file (relative to terraform directory)"
  type        = string
  default     = "../flink-sql/dim_enriched_tx/sql-scripts/dml.txp_dim_enriched_tx.sql"
}

variable "dml_properties_path" {
  description = "Path to DML properties file (relative to terraform directory)"
  type        = string
  default     = "../flink-sql/dim_enriched_tx/sql-scripts/dml.txp_dim_enriched_tx.properties"
}

variable "flink_max_cfu" {
  description = "Maximum CFU for Flink compute pool"
  type        = number
  default     = 20
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "tx-enriched"
}

variable "create_compute_pool" {
  description = "Whether to create a new Flink compute pool. If false, use existing flink_compute_pool_id"
  type        = bool
  default     = true
}
