# Data Sources
# These data blocks fetch information from AWS to support resource configuration.
# They enable dynamic reference to existing AWS resources without hardcoding.

# Fetch available Availability Zones in the current region.
# Used to distribute infrastructure across multiple AZs for high availability.
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetch current AWS account ID and user information.
# Used for resource naming, policy ARNs, and security group rules.
data "aws_caller_identity" "current" {}

