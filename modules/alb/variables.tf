########################################
# ALB MODULE VARIABLES
########################################
# Input variables for Application Load Balancer configuration

variable "name_prefix" {
  description = "Prefix used for ALB resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet identifiers for the ALB."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the ALB."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS."
  type        = string
}

variable "app_port" {
  description = "Port exposed by the application instances."
  type        = number
}

variable "health_check_path" {
  description = "Application health check path."
  type        = string
  default     = "/health"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB."
  type        = bool
  default     = true
}

variable "enable_access_logs" {
  description = "Enable S3 access logs for the ALB."
  type        = bool
  default     = false
}

variable "access_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "Optional prefix used for ALB access logs in S3."
  type        = string
  default     = "alb"
}

variable "tags" {
  description = "Common tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
