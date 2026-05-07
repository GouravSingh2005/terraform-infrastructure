########################################
# BOOTSTRAP MODULE OUTPUTS
########################################
# Exported S3 bucket and DynamoDB table references

output "state_bucket_name" {
  description = "S3 bucket name used for Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking."
  value       = aws_dynamodb_table.lock.name
}
