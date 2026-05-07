########################################
# TERRAFORM STATE BUCKET CONFIGURATION
########################################
# S3 bucket with versioning and encryption for remote state storage.
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Terraform   = "true"
  }

  state_bucket_name = coalesce(var.state_bucket_name, "${var.project_name}-${var.environment}-tfstate")
  lock_table_name   = coalesce(var.lock_table_name, "${var.project_name}-${var.environment}-tf-locks")
}

########################################
# TERRAFORM STATE S3 BUCKET
########################################
# Stores Terraform state files with versioning enabled for state recovery.
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  tags = local.common_tags
}

########################################
# STATE BUCKET VERSIONING
########################################
# Enables version history for disaster recovery and audit trails.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

########################################
# STATE BUCKET ENCRYPTION
########################################
# Server-side encryption at rest for sensitive state data.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

########################################
# STATE BUCKET PUBLIC ACCESS BLOCKING
########################################
# Prevents accidental public exposure of sensitive state data.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# DYNAMODB STATE LOCK TABLE
########################################
# Prevents concurrent Terraform applies via state locking mechanism.
resource "aws_dynamodb_table" "lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}
