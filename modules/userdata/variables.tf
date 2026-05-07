########################################
# USERDATA MODULE VARIABLES
########################################
# Input variables for user data script template rendering

variable "app_name" {
  description = "Application name used in the user data script."
  type        = string
}

variable "app_port" {
  description = "Port the application listens on."
  type        = number
}

variable "aws_region" {
  description = "AWS region used by the CloudWatch agent configuration."
  type        = string
}

variable "cloudwatch_application_log_group" {
  description = "CloudWatch Logs group for application output."
  type        = string
}

variable "cloudwatch_userdata_log_group" {
  description = "CloudWatch Logs group for user data output."
  type        = string
}
