terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Application = "permit-desk"
      Department  = "development-services"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_vpc" "city" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.city.id]
  }

  tags = {
    Tier = "private"
  }
}

# ---------------------------------------------------------------------------
# Applicant attachments. Plan sets and supporting documents are public records
# once a permit issues, but they are served through the portal, never directly.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "attachments" {
  bucket = "${var.name_prefix}-permit-attachments"
}

resource "aws_s3_bucket_public_access_block" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_key.records.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "records" {
  description             = "Permit Desk applicant records"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# ---------------------------------------------------------------------------
# Event bus
# ---------------------------------------------------------------------------

resource "aws_security_group" "broker" {
  name        = "${var.name_prefix}-msk"
  description = "Permit Desk MSK cluster"
  vpc_id      = data.aws_vpc.city.id

  ingress {
    description = "Kafka clients"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_msk_cluster" "bus" {
  cluster_name           = "${var.name_prefix}-bus"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = var.broker_count

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = data.aws_subnets.private.ids
    security_groups = [aws_security_group.broker.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.broker_storage_gb
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = false
    }
  }
}

# ---------------------------------------------------------------------------
# Application database
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "permit_desk" {
  name       = "${var.name_prefix}-permit-desk"
  subnet_ids = data.aws_subnets.private.ids
}

resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-permit-desk-db"
  description = "Permit Desk database"
  vpc_id      = data.aws_vpc.city.id

  ingress {
    description = "Postgres from the application subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.application_subnet_cidrs
  }
}

resource "aws_db_instance" "permit_desk" {
  identifier     = "${var.name_prefix}-permit-desk"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.database_instance_class

  allocated_storage     = var.database_storage_gb
  max_allocated_storage = var.database_storage_gb * 4

  db_name  = "permitdesk"
  username = var.database_username
  password = var.database_password

  db_subnet_group_name   = aws_db_subnet_group.permit_desk.name
  vpc_security_group_ids = [aws_security_group.database.id]

  storage_encrypted = true
  kms_key_id        = aws_kms_key.records.arn

  backup_retention_period = 14
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.name_prefix}-permit-desk-final"
}
