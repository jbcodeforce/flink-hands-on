terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.58.0"
    }
  }
}

provider "confluent" {
  cloud_api_key         = var.confluent_cloud_api_key
  cloud_api_secret      = var.confluent_cloud_api_secret
}

data "confluent_organization" "org" {}

locals {
  # Resolve artifact file path - handle both absolute and relative paths
  # abspath() resolves relative to the current working directory where terraform is executed
  artifact_file_path = startswith(var.artifact_file, "/") ? var.artifact_file : abspath(var.artifact_file)
  
  # Extract artifact ID and version after upload
  plugin_id  = confluent_flink_artifact.main.id
  version_id = confluent_flink_artifact.main.versions[0].version
}

resource "confluent_flink_artifact" "main" {
  environment {
    id = var.environment_id
  }
  region             = var.cloud_region
  cloud              = var.cloud_provider
  display_name       = var.display_name
  content_format     = var.content_format
  documentation_link = var.documentation_link
  artifact_file      = local.artifact_file_path
}

resource "confluent_flink_statement" "create-function" {
  organization {
    id = data.confluent_organization.org.id
  }
  
  environment {
    id = var.environment_id
  }
  compute_pool {
    id = var.flink_compute_pool_id
  }
  principal {
    id = var.flink_principal_id  
}

  # Register the EXPLODE function using the uploaded artifact
  statement = "CREATE FUNCTION EXPLODE AS 'io.confluent.udf.ExplodeFunction' USING JAR 'confluent-artifact://${local.plugin_id}/${local.version_id}';"
  properties = {
    "sql.current-catalog"  = var.current_catalog
    "sql.current-database" = var.current_database
    
  }

  rest_endpoint = var.flink_rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }

  lifecycle {
    prevent_destroy = true
  }
}