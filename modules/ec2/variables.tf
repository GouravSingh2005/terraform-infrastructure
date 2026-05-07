########################################
# EC2 MODULE VARIABLES
########################################
# Input variables for launch template configuration

variable "name_prefix" {
  description = "Prefix used for launch template names."
  type        = string
}

variable "ami_id" {
  description = "Optional custom AMI ID. If null, the latest Amazon Linux 2 AMI is used."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name attached to the launch template."
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to the application instances."
  type        = list(string)
}

variable "user_data_base64" {
  description = "Base64-encoded user data script."
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Common tags applied to launch template resources."
  type        = map(string)
  default     = {}
}
