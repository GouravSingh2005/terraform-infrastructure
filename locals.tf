########################################
# LOCAL VALUES AND CONFIGURATION
########################################
# These locals derive computed values from variables and data sources.
# They reduce code duplication and improve maintainability by centralizing
# naming conventions, tag strategies, and resource naming logic.

locals {
  # Standard prefix applied to resource names for quick identification
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags applied to ALL resources via default_tags in the provider.
  # Enforces consistent tagging for cost allocation, access control, and automation.
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Terraform   = "true"
  }

  # Select the first 2 availability zones from the region for multi-AZ deployment
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  # S3 bucket and DynamoDB table names for remote state and locking.
  # Defaults are used if custom names are not provided.
  alb_access_logs_bucket_name = coalesce(var.alb_access_logs_bucket_name, "${local.name_prefix}-alb-logs")
  tf_state_bucket_name        = coalesce(var.tf_state_bucket_name, "${local.name_prefix}-tfstate")
  tf_lock_table_name          = coalesce(var.tf_lock_table_name, "${local.name_prefix}-tf-locks")

  # Terraform state file key path within the S3 bucket
  tf_state_key = "${var.project_name}/${var.environment}/terraform.tfstate"

  # GitHub owner/repo may be provided as a single "owner/repo" string.
  # Parse it into `github_owner` and `github_repo` when present; fall back
  # to the explicit variables if those are set.
  github_owner = var.github_repository != null && length(split("/", var.github_repository)) == 2 ? split("/", var.github_repository)[0] : var.github_owner
  github_repo  = var.github_repository != null && length(split("/", var.github_repository)) == 2 ? split("/", var.github_repository)[1] : var.github_repo

  # Pipeline is only created if a CodeStar connection ARN exists and we have
  # both owner and repo available (either parsed or provided explicitly).
  pipeline_enabled = var.codestar_connection_arn != null && local.github_owner != null && local.github_repo != null

  # Resource naming conventions - used for infrastructure resource identification
  application_name  = "${local.name_prefix}-app"
  vpc_name          = "${local.name_prefix}-vpc"
  alb_name          = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"

  # CloudWatch log group names for centralized logging from EC2 instances
  cloudwatch_application_log_group = "/aws/ec2/${local.name_prefix}/application"
  cloudwatch_userdata_log_group    = "/aws/ec2/${local.name_prefix}/userdata"

  # Canonical application URL used in documentation and health checks
  application_url = "https://${var.subdomain}.${var.domain_name}"
}
