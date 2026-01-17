
# -----------------------------------------------------------------------------
# Confluent Cloud API Credentials
# -----------------------------------------------------------------------------
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Artifact Configuration
# -----------------------------------------------------------------------------
variable "artifact_file" {
  description = "Path to .zip / .jar for Flink Artifact. Can be absolute path or relative to the directory where terraform is executed."
  type        = string
  default     = "flink_artifact.jar"
}

variable "display_name" {
  description = "Display name for the Flink artifact"
  type        = string
  default     = "explode-udf"
}

variable "content_format" {
  description = "Content format of the artifact (JAR, ZIP, etc.)"
  type        = string
  default     = "JAR"
  validation {
    condition     = contains(["JAR", "ZIP"], upper(var.content_format))
    error_message = "Content format must be one of: JAR, ZIP"
  }
}

variable "documentation_link" {
  description = "URL to documentation for the artifact"
  type        = string
  default     = "https://github.com/jbcodeforce/flink-udfs-catalog/tree/main/explode"
}

# -----------------------------------------------------------------------------
# Confluent Cloud Organization and Environment
# -----------------------------------------------------------------------------
variable "environment_id" {
  description = "The ID of the managed environment on Confluent Cloud."
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider for deployment (AWS, GCP, or AZURE)"
  type        = string
  default     = "AWS"
  validation {
    condition     = contains(["AWS", "GCP", "AZURE"], upper(var.cloud_provider))
    error_message = "Cloud provider must be one of: AWS, GCP, AZURE"
  }
}

variable "cloud_region" {
  description = "Confluent Cloud region for deployment"
  type        = string
  default     = "us-west-2"
}

# In Confluent Cloud, an environment is mapped to a Flink catalog.
# See https://docs.confluent.io/cloud/current/flink/index.html#metadata-mapping-between-ak-cluster-topics-schemas-and-af
# for more details.
variable "current_catalog" {
  description = "The display name of the managed environment on Confluent Cloud."
  type        = string
}

variable "current_database" {
  description = "The display name of the managed Kafka Cluster on Confluent Cloud."
  type        = string
}

variable "flink_compute_pool_id" {
  description = "The ID of the managed Compute Pool on Confluent Cloud."
  type        = string
}

variable "flink_rest_endpoint" {
  description = "The REST endpoint of the target Flink Region on Confluent Cloud."
  type        = string
}

variable "flink_api_key" {
  description = "Flink API Key (also referred as Flink API ID) that should be owned by a principal with a FlinkAdmin role (provided by Ops team)"
  type        = string
}

variable "flink_api_secret" {
  description = "Flink API Secret (provided by Ops team)"
  type        = string
  sensitive   = true
}

# FlinkAdmin principal needs an Assigner role binding on flink_principal_id principal.
# See https://github.com/confluentinc/terraform-provider-confluent/blob/master/examples/configurations/flink-quickstart/main.tf#L64
variable "flink_principal_id" {
  description = "Service account to perform a task within Confluent Cloud, such as executing a Flink statement."
  type        = string
}