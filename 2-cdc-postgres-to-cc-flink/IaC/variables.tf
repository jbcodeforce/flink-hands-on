# -----------------------------------------------------------------------------
# Variables Configuration
# CDC Postgres to Confluent Cloud Flink
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------
variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "cdc-postgres"
}

variable "owner_email" {
  description = "Email of the resource owner for tagging"
  type        = string
}

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
variable "cloud_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-2"
}

variable "existing_vpc_id" {
  description = "ID of existing VPC to deploy into"
  type        = string
}

variable "existing_subnet_ids" {
  description = "List of existing subnet IDs in the VPC (optional - will auto-discover if not provided)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Configuration
# -----------------------------------------------------------------------------
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_username" {
  description = "PostgreSQL database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "db_publicly_accessible" {
  description = "Whether the RDS instance should be publicly accessible"
  type        = bool
  default     = true
}

variable "create_tables_automatically" {
  description = "Whether to automatically create database tables using psql (requires psql to be installed)"
  type        = bool
  default     = true
}

variable "db_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access RDS (in addition to Confluent Cloud IPs). For production, restrict to specific IPs."
  type        = list(string)
  default     = []
}

variable "confluent_cloud_cidr_blocks" {
  description = <<-EOT
    List of Confluent Cloud IP addresses/CIDR blocks for CDC connector access to RDS.
    These are the egress IPs from Confluent Cloud connectors.
    
    IMPORTANT: Update this list with the latest IPs from:
    - Confluent Cloud UI: Connectors → Your Connector → Networking
    - Confluent Cloud documentation: https://docs.confluent.io/cloud/current/networking/ip-ranges.html
    
    The default list includes common Confluent Cloud connector egress IPs.
    You should verify and update this list for your specific Confluent Cloud environment.
  EOT
  type        = list(string)
  default = [
    # Confluent Cloud connector egress IPs (common ranges)
    # Update with your specific Confluent Cloud environment IPs
    "35.80.209.50/32"
  ]
}

variable "allow_all_cidr_blocks" {
  description = "Allow access from all IPs (0.0.0.0/0). WARNING: Only use for testing. Set to false for production."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Confluent Cloud Configuration
# Note: Confluent Cloud resources are managed by base infrastructure
# This module only needs API credentials for managing connectors and ACLs
# -----------------------------------------------------------------------------
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (can be set via CONFLUENT_CLOUD_API_KEY env var). Required for connector and ACL management."
  type        = string
  default     = ""
  # Will use environment variable if not provided
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret (can be set via CONFLUENT_CLOUD_API_SECRET env var). Required for connector and ACL management."
  type        = string
  sensitive   = true
  default     = ""
  # Will use environment variable if not provided
}

# -----------------------------------------------------------------------------
# Confluent Cloud Service Accounts (Reusing Existing)
# -----------------------------------------------------------------------------
variable "app_manager_sa_id" {
  description = "Existing Confluent service account ID for app manager (optional - will create new if not provided)"
  type        = string
  default     = ""
}

variable "connectors_sa_id" {
  description = "Existing Confluent service account ID for connectors (optional - will create new if not provided)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# IAM Configuration (Reusing Existing)
# -----------------------------------------------------------------------------
variable "iam_role_arn" {
  description = "Existing IAM role ARN to reuse (optional - for future use if needed)"
  type        = string
  default     = ""
}

variable "iam_policy_arn" {
  description = "Existing IAM policy ARN to reuse (optional - for future use if needed)"
  type        = string
  default     = ""
}
