# Terraform Version and Provider Requirements
# This file ensures minimum versions are enforced to maintain compatibility
# and access to the latest AWS provider features and security updates.

terraform {
  # Minimum Terraform version required for this configuration.
  # Version 1.5+ provides improved error messages and performance.
  required_version = ">= 1.5.0"

  required_providers {
    # AWS provider is pinned to version 5.0+ for access to modern AWS resources
    # and to avoid breaking changes from major version upgrades.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
