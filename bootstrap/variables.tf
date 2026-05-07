########################################
# BOOTSTRAP MODULE VARIABLES
########################################
# Input variables for state backend provisioning

variable "region" {
  description = "AWS region used for the bootstrap stack."
  type        = string
}

variable "environment" {
  description = "Environment name used for backend resource naming."
  type        = string
}

variable "project_name" {
  description = "Project name used for backend resource naming."
  type        = string
}

variable "owner" {
  description = "Owner tag value applied to backend resources."
  type        = string
}

variable "state_bucket_name" {
  description = "Optional custom S3 bucket name for Terraform state."
  type        = string
  default     = null
}

variable "lock_table_name" {
  description = "Optional custom DynamoDB table name for state locking."
  type        = string
  default     = null
}
