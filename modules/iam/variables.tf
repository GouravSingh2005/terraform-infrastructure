########################################
# IAM MODULE VARIABLES
########################################
# Input variables for EC2 IAM role and policies

variable "name_prefix" {
  description = "Prefix used for IAM resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
