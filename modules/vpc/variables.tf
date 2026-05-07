########################################
# VPC MODULE VARIABLES
########################################
# Input variables for VPC, subnets, and network configuration

variable "name_prefix" {
  description = "Prefix used for all VPC resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Two availability zones used by the VPC."
  type        = list(string)

  validation {
    condition     = length(var.azs) == 2
    error_message = "Exactly two availability zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDR blocks."
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDR blocks."
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to VPC resources."
  type        = map(string)
  default     = {}
}
