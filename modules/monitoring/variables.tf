########################################
# MONITORING MODULE VARIABLES
########################################
# Input variables for CloudWatch log groups and alarms

variable "name_prefix" {
  description = "Prefix used for monitoring resources."
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name monitored by alarms."
  type        = string
}

variable "asg_min_size" {
  description = "Minimum Auto Scaling Group size used for alarm thresholds."
  type        = number
}

variable "lb_arn_suffix" {
  description = "ALB ARN suffix used by CloudWatch metrics."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix used by CloudWatch metrics."
  type        = string
}

variable "application_log_group_name" {
  description = "CloudWatch log group for application logs."
  type        = string
}

variable "userdata_log_group_name" {
  description = "CloudWatch log group for user data logs."
  type        = string
}

variable "alarm_actions" {
  description = "SNS topic ARNs used for alarm actions."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags applied to monitoring resources."
  type        = map(string)
  default     = {}
}
