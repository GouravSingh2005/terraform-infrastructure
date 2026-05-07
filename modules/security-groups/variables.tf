########################################
# SECURITY GROUPS MODULE VARIABLES
########################################
# Input variables for security group configuration

variable "name_prefix" {
  description = "Prefix used for security group names."
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier."
  type        = string
}

variable "app_port" {
  description = "Application port allowed from the ALB to instances."
  type        = number
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to reach SSH on the application instances."
  type        = string
}

variable "database_port" {
  description = "Database port used by the placeholder DB security group."
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Common tags applied to security groups."
  type        = map(string)
  default     = {}
}
