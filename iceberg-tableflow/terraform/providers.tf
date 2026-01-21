# -----------------------------------------------------------------------------
# Terraform Providers Configuration
# Tableflow Configuration for Transaction Enriched Topic
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# -----------------------------------------------------------------------------
# Confluent Cloud Provider
# -----------------------------------------------------------------------------
# The provider will automatically use CONFLUENT_CLOUD_API_KEY and 
# CONFLUENT_CLOUD_API_SECRET environment variables if these variables are empty
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key != "" ? var.confluent_cloud_api_key : null
  cloud_api_secret = var.confluent_cloud_api_secret != "" ? var.confluent_cloud_api_secret : null
}
