# -----------------------------------------------------------------------------
# AWS Infrastructure
# Card Transaction Processing Demo
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# AWS Data Sources
# -----------------------------------------------------------------------------

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Note: S3 bucket is referenced by name only (local.s3_bucket_name)
# The bucket should exist before deploying this configuration
# No data source is used to avoid validation errors if bucket is created elsewhere

# -----------------------------------------------------------------------------
# AWS Glue Data Catalog
# -----------------------------------------------------------------------------

# Glue Database for Iceberg tables (Tableflow will create tables here)
resource "aws_glue_catalog_database" "tx_iceberg_db" {
  name        = "${var.prefix}-iceberg-${random_id.env_display_id.hex}"
  description = "Glue database for Card Transaction Iceberg tables from Tableflow"

  catalog_id = data.aws_caller_identity.current.account_id

  location_uri = "s3://${local.s3_bucket_name}/"

  tags = {
    Name        = "${var.prefix}-iceberg-database"
    Environment = var.prefix
  }
}

# -----------------------------------------------------------------------------
# AWS Athena
# -----------------------------------------------------------------------------

# Athena Workgroup for querying Iceberg tables
resource "aws_athena_workgroup" "tx_workgroup" {
  name        = "${var.prefix}-athena-workgroup-${random_id.env_display_id.hex}"
  description = "Athena workgroup for querying Card Transaction Iceberg tables"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${local.s3_bucket_name}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  tags = {
    Name        = "${var.prefix}-athena-workgroup"
    Environment = var.prefix
  }
}

# -----------------------------------------------------------------------------
# IAM Roles and Policies for Glue and Athena
# -----------------------------------------------------------------------------

# Locals to determine final IAM role ARN (use provided or created)
# Single IAM role used for both Glue and Athena
locals {
  iam_role_arn_final = local.iam_role_arn != "" ? local.iam_role_arn : try(aws_iam_role.shared_service_role[0].arn, "")
}

# IAM role for Glue and Athena (only create if ARN not provided)
# This role supports both Glue and Athena services
resource "aws_iam_role" "shared_service_role" {
  count = local.iam_role_arn == "" ? 1 : 0

  name = "${var.prefix}-glue-athena-service-role-${random_id.env_display_id.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "glue.amazonaws.com",
            "athena.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "${var.prefix}-glue-athena-service-role"
    Environment = var.prefix
  }
}

# IAM policy for Glue to access S3 bucket (only create if policy ARN not provided)
resource "aws_iam_role_policy" "glue_s3_access" {
  count = local.glue_s3_policy_arn == "" && local.iam_role_arn == "" ? 1 : 0
  name  = "${var.prefix}-glue-s3-access-${random_id.env_display_id.hex}"
  role  = aws_iam_role.shared_service_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.s3_bucket_name}",
          "arn:aws:s3:::${local.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach AWS managed policy for Glue service role (only if role was created)
resource "aws_iam_role_policy_attachment" "glue_service_role_policy" {
  count      = local.iam_role_arn == "" ? 1 : 0
  role       = aws_iam_role.shared_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# IAM policy for Athena to access S3 and Glue (only create if policy ARN not provided)
# Uses the shared service role (same as Glue)
resource "aws_iam_role_policy" "athena_access" {
  count = local.athena_access_policy_arn == "" && local.iam_role_arn == "" ? 1 : 0
  name  = "${var.prefix}-athena-access-${random_id.env_display_id.hex}"
  role  = aws_iam_role.shared_service_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.s3_bucket_name}",
          "arn:aws:s3:::${local.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:BatchGetPartition"
        ]
        Resource = [
          "arn:aws:glue:${var.cloud_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.cloud_region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.tx_iceberg_db.name}",
          "arn:aws:glue:${var.cloud_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.tx_iceberg_db.name}/*"
        ]
      }
    ]
  })
}

# Note: Athena uses Glue Data Catalog by default, so no separate resource needed
# The Glue database created above will be accessible from Athena
