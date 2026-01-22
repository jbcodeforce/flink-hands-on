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

variable "owner_email" {
  description = "Email of the resource owner for tagging"
  type        = string
  default     = "jboyer@confluent.io"
}

variable "iac_state_path" {
  description = "Path to the IaC terraform state file (relative to this terraform directory). Set to empty string if not using remote state."
  type        = string
  default = "../../2-cdc-postgres-to-cc-flink/IaC/terraform.tfstate"
}

variable "cflt_state_path" {
  description = "Path to the IaC terraform state file (relative to this terraform directory). Set to empty string if not using remote state."
  type        = string
  default = "../../1-confluent-cloud-infrastructure/terraform.tfstate"
}

variable "topic_name" {
  description = "Name of the Kafka topic to enable Tableflow on (transaction enriched topic)"
  type        = string
  default     = "tx_enriched"
}

variable "enable_tableflow" {
  description = "Enable Tableflow on the topic"
  type        = bool
  default     = true
}

variable "prefix" {
    description = "Name of the Kafka topic to enable Tableflow on (transaction enriched topic)"
  type        = string
  default     = "txp"
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

variable "flink_service_account_id" {
  description = "Flink service account ID - reused for app management, deployment, and compute pool operations (required if not using remote state). This service account serves as the principal for Flink statements."
  type        = string
  default     = ""
}

variable "flink_api_key" {
  description = "Flink API Key ID from the flink_service_account_id (required if not using remote state). Should be an API key associated with flink_service_account_id."
  type        = string
  default     = ""
  sensitive   = true
}

variable "flink_api_secret" {
  description = "Flink API Secret from the flink_service_account_id (required if not using remote state)"
  type        = string
  default     = ""
  sensitive   = true
}

# Legacy variable name for backward compatibility
variable "app_manager_service_account_id" {
  description = "[DEPRECATED] Use flink_service_account_id instead. App Manager service account ID for Flink statements (required if not using remote state)"
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


variable "create_compute_pool" {
  description = "Whether to create a new Flink compute pool. If false, use existing flink_compute_pool_id"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# AWS IAM Configuration (Optional - for reusing existing resources)
# -----------------------------------------------------------------------------
variable "iam_role_arn" {
  description = "Existing IAM role ARN to reuse for both Glue and Athena (optional - will create new if not provided). The role must have trust policies for both glue.amazonaws.com and athena.amazonaws.com services."
  type        = string
  default     = ""
}

variable "iam_policy_name" {
  description = "Existing Glue S3 access policy ARN to reuse (optional - will create new if not provided)"
  type        = string
  default     = ""
}



