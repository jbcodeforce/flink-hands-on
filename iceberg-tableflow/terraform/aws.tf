# -----------------------------------------------------------------------------
# AWS Infrastructure
# Card Transaction Processing Demo
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC Data Sources (Reusing Existing VPC)
# -----------------------------------------------------------------------------
data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

# Auto-discover subnets if not explicitly provided
data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }
}

locals {
  subnet_ids = length(var.existing_subnet_ids) > 0 ? var.existing_subnet_ids : data.aws_subnets.existing.ids
}

# Get subnet details for the first subnet (for RDS)
data "aws_subnet" "primary" {
  id = local.subnet_ids[0]
}

# Get all subnet details for route table validation
data "aws_subnet" "all" {
  for_each = toset(local.subnet_ids)
  id       = each.value
}

# Find Internet Gateway in the VPC (optional - may not exist)
data "aws_internet_gateway" "vpc_igws" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# Get route tables associated with each subnet
data "aws_route_tables" "subnet_route_tables" {
  for_each = toset(local.subnet_ids)
  filter {
    name   = "association.subnet-id"
    values = [each.value]
  }
}

# Get route table details to check for IGW routes
data "aws_route_table" "subnet_route_table" {
  for_each = {
    for subnet_id in local.subnet_ids : subnet_id => try(
      data.aws_route_tables.subnet_route_tables[subnet_id].ids[0],
      null
    )
    if length(data.aws_route_tables.subnet_route_tables[subnet_id].ids) > 0
  }
  route_table_id = each.value
}

# Validation: Ensure all RDS subnets have route tables with IGW routes
# This will fail during plan/apply if subnets don't have IGW routes
locals {
  # Get IGW ID if it exists
  vpc_igw_id = length(data.aws_internet_gateway.vpc_igws.id) > 0 ? data.aws_internet_gateway.vpc_igws.id : null
  
  # Check if each subnet's route table has a route to the IGW
  subnet_igw_validation = {
    for subnet_id in local.subnet_ids : subnet_id => {
      subnet_id      = subnet_id
      subnet_cidr    = data.aws_subnet.all[subnet_id].cidr_block
      route_table_id = try(
        data.aws_route_tables.subnet_route_tables[subnet_id].ids[0],
        "NO_ROUTE_TABLE"
      )
      has_route_table = length(data.aws_route_tables.subnet_route_tables[subnet_id].ids) > 0
      has_igw_route = local.vpc_igw_id != null && try(
        length([
          for route in data.aws_route_table.subnet_route_table[subnet_id].routes : route
          if route.gateway_id == local.vpc_igw_id && route.gateway_id != ""
        ]) > 0,
        false
      )
    }
  }
  
  # Collect subnets without IGW routes for error message
  subnets_without_igw = [
    for k, v in local.subnet_igw_validation : v
    if !v.has_igw_route || !v.has_route_table
  ]
}

# -----------------------------------------------------------------------------
# AWS Glue Data Catalog
# -----------------------------------------------------------------------------

# Glue Database for Iceberg tables (Tableflow will create tables here)
resource "aws_glue_catalog_database" "card_tx_iceberg_db" {
  name        = "${var.prefix}-iceberg-${random_id.env_display_id.hex}"
  description = "Glue database for Card Transaction Iceberg tables from Tableflow"

  catalog_id = data.aws_caller_identity.current.account_id

  tags = {
    Name = "${var.prefix}-iceberg-database"
  }
}

# -----------------------------------------------------------------------------
# AWS Athena
# -----------------------------------------------------------------------------

# Athena Workgroup for querying Iceberg tables
resource "aws_athena_workgroup" "card_tx_workgroup" {
  name        = "${var.prefix}-athena-workgroup-${random_id.env_display_id.hex}"
  description = "Athena workgroup for querying Card Transaction Iceberg tables"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.card_tx_iceberg.bucket}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  tags = {
    Name = "${var.prefix}-athena-workgroup"
  }
}

# Athena Data Catalog (uses Glue by default, but we can configure it explicitly)
# Note: Athena uses Glue Data Catalog by default, so no separate resource needed
# The Glue database created above will be accessible from Athena
