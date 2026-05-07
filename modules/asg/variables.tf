########################################
# AUTO SCALING GROUP MODULE VARIABLES
########################################
# Input variables for ASG configuration and scaling policies

variable "name_prefix" {
  description = "Prefix used for the Auto Scaling Group name."
  type        = string
}

variable "launch_template_id" {
  description = "Launch template identifier."
  type        = string
}

variable "launch_template_version" {
  description = "Launch template version."
  type        = string
}

variable "vpc_zone_identifier" {
  description = "Private subnet identifiers used by the Auto Scaling Group."
  type        = list(string)
}

variable "target_group_arns" {
  description = "Target group ARNs attached to the Auto Scaling Group."
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired instance count."
  type        = number
}

variable "min_size" {
  description = "Minimum instance count."
  type        = number
}

variable "max_size" {
  description = "Maximum instance count."
  type        = number
}

variable "health_check_type" {
  description = "Auto Scaling health check type."
  type        = string
  default     = "ELB"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds."
  type        = number
  default     = 180
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for automatic scaling."
  type        = number
  default     = 50
}

variable "tags" {
  description = "Common tags applied to the Auto Scaling Group."
  type        = map(string)
  default     = {}
}
