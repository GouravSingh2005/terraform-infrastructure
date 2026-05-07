########################################
# AWS REGION AND ENVIRONMENT
########################################
variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, such as dev, stage, or prod."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Logical project name used in naming and tagging."
  type        = string
  default     = "enterprise-3tier"
}

variable "owner" {
  description = "Owner tag value for all resources."
  type        = string
  default     = "platform-team"
}

########################################
# NETWORK CONFIGURATION
########################################
variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_app_subnet_cidrs" {
  description = "Two private application subnet CIDRs."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2
    error_message = "Exactly two private application subnet CIDRs are required."
  }
}

variable "private_db_subnet_cidrs" {
  description = "Two private database subnet CIDRs."
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnet_cidrs) == 2
    error_message = "Exactly two private database subnet CIDRs are required."
  }
  default = ["10.20.20.0/24", "10.20.21.0/24"]
}

########################################
# APPLICATION TIER CONFIGURATION
########################################
variable "instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of application instances."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of application instances."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of application instances."
  type        = number
  default     = 4
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to reach SSH on the private application instances."
  type        = string
  # Default is null to disable SSH ingress unless explicitly provided.
  default = null
}

########################################
# LOAD BALANCER AND DOMAIN CONFIGURATION
########################################
variable "domain_name" {
  description = "Root domain name managed outside Route 53."
  type        = string
  default     = "example.com"
}

variable "subdomain" {
  description = "Subdomain mapped via CNAME to the ALB DNS name."
  type        = string
  default     = "app"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener."
  type        = string
  # Intentionally no default: user MUST provide this ARN
}

########################################
# GITHUB REPOSITORY (SINGLE INPUT)
########################################
# Provide a single value in the form "owner/repo". When set, locals will
# parse this into `github_owner` and `github_repo`. If left null, pipeline is
# disabled unless `codestar_connection_arn` and owner/repo variables are set.
variable "github_repository" {
  description = "GitHub repository in the form 'owner/repo'."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "app_port" {
  description = "Application port exposed by the instance and target group."
  type        = number
  default     = 3000
}

########################################
# STORAGE AND LOGGING CONFIGURATION
########################################
variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB."
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logs to S3."
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket_name" {
  description = "Optional S3 bucket name for ALB access logs."
  type        = string
  default     = null
}

########################################
# TERRAFORM STATE BACKEND CONFIGURATION
########################################
variable "tf_state_bucket_name" {
  description = "Optional override for the Terraform state bucket name."
  type        = string
  default     = null
}

variable "tf_lock_table_name" {
  description = "Optional override for the Terraform state lock table name."
  type        = string
  default     = null
}

########################################
# CI/CD AND GITHUB CONFIGURATION
########################################
variable "codestar_connection_arn" {
  description = "Existing CodeStar Connections ARN for GitHub source integration."
  type        = string
  default     = null
}

variable "github_owner" {
  description = "GitHub organization or user that owns the repository."
  type        = string
  default     = null
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = null
}

variable "github_branch" {
  description = "GitHub branch used by the pipeline."
  type        = string
  default     = "main"
}

########################################
# MONITORING AND ALERTING CONFIGURATION
########################################
variable "monitoring_alarm_actions" {
  description = "Optional list of SNS topic ARNs for CloudWatch alarm actions."
  type        = list(string)
  default     = []
}
