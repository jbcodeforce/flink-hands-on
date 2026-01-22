# -----------------------------------------------------------------------------
# AWS Infrastructure
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

# Get subnet details for validation
data "aws_subnet" "all" {
  for_each = toset(local.subnet_ids)
  id       = each.value
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

# Security group for RDS PostgreSQL
resource "aws_security_group" "postgres_db_sg" {
  name        = "${var.prefix}-db-sg-${random_id.env_display_id.hex}"
  description = "Security group for PostgreSQL database"
  vpc_id      = data.aws_vpc.existing.id

  tags = {
    Name = "${var.prefix}-db-sg"
  }
}

# Combine Confluent Cloud IPs with user-specified IPs
locals {
  # Combine all allowed CIDR blocks
  all_allowed_cidr_blocks = var.allow_all_cidr_blocks ? ["0.0.0.0/0"] : concat(
    var.confluent_cloud_cidr_blocks,
    var.db_allowed_cidr_blocks
  )
}

# Inbound rule for PostgreSQL
# Combines Confluent Cloud connector IPs with user-specified IPs
resource "aws_security_group_rule" "allow_inbound_postgres" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.postgres_db_sg.id
  cidr_blocks       = local.all_allowed_cidr_blocks
  description       = "Allow PostgreSQL inbound traffic from Confluent Cloud connectors and specified IPs"
}

# Outbound rule for PostgreSQL
resource "aws_security_group_rule" "allow_outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.postgres_db_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# RDS Subnet Group
# -----------------------------------------------------------------------------
# NOTE: This is NOT creating new subnets. RDS requires a DB subnet group
# which is just a logical grouping of existing subnets from your VPC.
# We're using the same subnets discovered from your existing VPC.
resource "aws_db_subnet_group" "postgres_db_subnet_group" {
  name       = "${var.prefix}-db-subnet-group-${random_id.env_display_id.hex}"
  subnet_ids = local.subnet_ids  # Uses existing subnets from your VPC

  tags = {
    Name = "${var.prefix}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# RDS Parameter Group (Enable Logical Replication for Debezium CDC)
# -----------------------------------------------------------------------------
resource "aws_db_parameter_group" "postgres_pg_params" {
  name   = "${var.prefix}-pg-debezium-${random_id.env_display_id.hex}"
  family = "postgres17"

  parameter {
    apply_method = "pending-reboot"
    name         = "rds.logical_replication"
    value        = "1"
  }

  tags = {
    Name = "${var.prefix}-pg-debezium-params"
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Instance
# -----------------------------------------------------------------------------
resource "aws_db_instance" "postgres_db" {
  identifier     = "${var.prefix}-db-${random_id.env_display_id.hex}"
  engine         = "postgres"
  engine_version = "17.4"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  db_name  = "postgresdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.postgres_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.postgres_db_sg.id]
  parameter_group_name   = aws_db_parameter_group.postgres_pg_params.name

  publicly_accessible = var.db_publicly_accessible
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name = "${var.prefix}-postgresql"
  }
}

# -----------------------------------------------------------------------------
# Create Database Tables
# -----------------------------------------------------------------------------
# NOTE: This requires 'psql' to be installed on the machine running Terraform.
# If psql is not available, set create_tables_automatically = false and run manually:
#   psql -h <rds-endpoint> -U postgres -d postgresdb -f schema.sql
#
# To install psql:
#   macOS: brew install postgresql
#   Ubuntu/Debian: sudo apt-get install postgresql-client
#   RHEL/CentOS: sudo yum install postgresql
resource "null_resource" "create_tables" {
  count = var.create_tables_automatically ? 1 : 0

  depends_on = [aws_db_instance.postgres_db]

  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v psql &> /dev/null; then
        echo "ERROR: psql command not found. Please install PostgreSQL client tools."
        echo ""
        echo "Installation instructions:"
        echo "  macOS:    brew install postgresql"
        echo "  Ubuntu:   sudo apt-get install postgresql-client"
        echo "  RHEL:     sudo yum install postgresql"
        echo ""
        echo "Alternatively, set create_tables_automatically = false in terraform.tfvars"
        echo "and run the schema manually:"
        echo "  psql -h ${aws_db_instance.postgres_db.address} -U ${var.db_username} -d ${aws_db_instance.postgres_db.db_name} -f ${path.module}/schema.sql"
        exit 1
      fi
      
      PGPASSWORD=${var.db_password} psql \
        -h ${aws_db_instance.postgres_db.address} \
        -p ${aws_db_instance.postgres_db.port} \
        -U ${var.db_username} \
        -d ${aws_db_instance.postgres_db.db_name} \
        -f ${path.module}/schema.sql
    EOT
  }

  triggers = {
    db_instance_id = aws_db_instance.postgres_db.id
  }
}
