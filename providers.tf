# AWS Provider Configuration
# Configures the primary AWS provider with default tags applied to all resources
# for consistent tracking, billing, and resource organization.

provider "aws" {
  # AWS region where resources will be deployed
  region = var.region

  # Default tags applied to ALL AWS resources created in this configuration.
  # These tags provide consistent tagging across the infrastructure for
  # cost allocation, access control, and operational tracking.
  default_tags {
    tags = local.common_tags
  }
}
