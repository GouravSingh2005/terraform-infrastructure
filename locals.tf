########################################
# LOCAL VALUES AND CONFIGURATION
########################################
# These locals derive computed values from variables and data sources.
# They reduce code duplication and improve maintainability by centralizing
# naming conventions, tag strategies, and resource naming logic.

locals {

  ########################################
  # RESOURCE NAMING
  ########################################

  # Standard prefix applied to resource names
  name_prefix = "${var.project_name}-${var.environment}"

  ########################################
  # COMMON TAGS
  ########################################

  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Terraform   = "true"
  }

  ########################################
  # AVAILABILITY ZONES
  ########################################

  # Select first 2 AZs for multi-AZ deployment
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )

  ########################################
  # REMOTE STATE CONFIGURATION
  ########################################

  # S3 bucket for ALB access logs
  alb_access_logs_bucket_name = coalesce(
    var.alb_access_logs_bucket_name,
    "${local.name_prefix}-alb-logs"
  )

  # Terraform state bucket
  tf_state_bucket_name = coalesce(
    var.tf_state_bucket_name,
    "${local.name_prefix}-tfstate"
  )

  # DynamoDB lock table
  tf_lock_table_name = coalesce(
    var.tf_lock_table_name,
    "${local.name_prefix}-tf-locks"
  )

  # Terraform remote state key
  tf_state_key = "${var.project_name}/${var.environment}/terraform.tfstate"

  ########################################
  # GITHUB REPOSITORY PARSING
  ########################################

  # Supports:
  # github_repository = "owner/repo"
  # OR separate github_owner/github_repo variables

  github_parts = (
    var.github_repository != null
    ? split("/", var.github_repository)
    : []
  )

  github_owner = (
    length(local.github_parts) == 2
    ? local.github_parts[0]
    : var.github_owner
  )

  github_repo = (
    length(local.github_parts) == 2
    ? local.github_parts[1]
    : var.github_repo
  )

  ########################################
  # PIPELINE ENABLEMENT
  ########################################

  # Pipeline enabled when repo info exists (Jenkins handles GitHub integration)
  # Note: codestar_connection_arn is deprecated and not used by Jenkins pipeline
  pipeline_enabled = (
    local.github_owner != null &&
    local.github_repo != null
  )

  ########################################
  # RESOURCE IDENTIFIERS
  ########################################

  application_name  = "${local.name_prefix}-app"
  vpc_name          = "${local.name_prefix}-vpc"
  alb_name          = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"

  ########################################
  # CLOUDWATCH LOG GROUPS
  ########################################

  cloudwatch_application_log_group = (
    "/aws/ec2/${local.name_prefix}/application"
  )

  cloudwatch_userdata_log_group = (
    "/aws/ec2/${local.name_prefix}/userdata"
  )

  ########################################
  # APPLICATION URL
  ########################################

  application_url = "https://${var.subdomain}.${var.domain_name}"
}