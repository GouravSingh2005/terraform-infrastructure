########################################
# VPC INFRASTRUCTURE MODULE
########################################
# Creates the primary VPC with public/private subnets across 2 AZs,
# Internet Gateway, NAT Gateway, and route tables for multi-tier architecture.
module "vpc" {
  source = "./modules/vpc"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  azs                      = local.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  tags                     = local.common_tags
}

########################################
# SECURITY GROUPS MODULE
########################################
# Creates isolated security groups for ALB (edge), application tier, and
# database tier with least-privilege inbound/outbound rules.
module "security_groups" {
  source = "./modules/security-groups"

  name_prefix      = local.name_prefix
  vpc_id           = module.vpc.vpc_id
  app_port         = var.app_port
  ssh_allowed_cidr = var.ssh_allowed_cidr
  database_port    = 5432
  tags             = local.common_tags
}

########################################
# IAM CONFIGURATION MODULE
########################################
# Provisions EC2 instance profiles, roles, and policies for secure
# AWS API access without hardcoded credentials.
module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

########################################
# USER DATA MODULE
########################################
# Renders production-grade user data script that installs dependencies,
# bootstraps the Node.js application, and configures CloudWatch logging.
module "userdata" {
  source = "./modules/userdata"

  app_name                         = local.application_name
  app_port                         = var.app_port
  aws_region                       = var.region
  cloudwatch_application_log_group = local.cloudwatch_application_log_group
  cloudwatch_userdata_log_group    = local.cloudwatch_userdata_log_group
}

########################################
# EC2 LAUNCH TEMPLATE MODULE
########################################
# Creates encrypted launch template with IMDSv2 enforcement,
# detailed monitoring enabled, and user data script for automatic provisioning.
module "ec2" {
  source = "./modules/ec2"

  name_prefix               = local.name_prefix
  ami_id                    = null
  instance_type             = var.instance_type
  key_name                  = var.key_name
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  security_group_ids        = [module.security_groups.app_security_group_id]
  user_data_base64          = module.userdata.user_data_base64
  root_volume_size          = var.root_volume_size
  tags                      = local.common_tags
}

########################################
# APPLICATION LOAD BALANCER MODULE
########################################
# Provisions internet-facing ALB with HTTPS listener using ACM certificate,
# HTTP-to-HTTPS redirect, and health checks for target group.
module "alb" {
  source = "./modules/alb"

  name_prefix                = local.name_prefix
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  security_group_ids         = [module.security_groups.alb_security_group_id]
  certificate_arn            = var.acm_certificate_arn
  app_port                   = var.app_port
  health_check_path          = "/health"
  enable_deletion_protection = var.enable_deletion_protection
  enable_access_logs         = var.enable_alb_access_logs
  access_logs_bucket_name    = local.alb_access_logs_bucket_name
  tags                       = local.common_tags
}

########################################
# ALB ACCESS LOGS STORAGE (OPTIONAL)
########################################
# S3 bucket for ALB access logs with versioning, encryption, and
# public access blocking. Only created if enable_alb_access_logs = true.
resource "aws_s3_bucket" "alb_access_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = local.alb_access_logs_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_access_logs[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.alb_access_logs[0].arn
      }
    ]
  })
}

########################################
# AUTO SCALING GROUP MODULE
########################################
# Manages application tier capacity with target tracking scaling policy,
# instance refresh strategy, and health check configuration.
module "asg" {
  source = "./modules/asg"

  name_prefix               = local.name_prefix
  launch_template_id        = module.ec2.launch_template_id
  launch_template_version   = "$Latest"
  vpc_zone_identifier       = module.vpc.private_app_subnet_ids
  target_group_arns         = [module.alb.target_group_arn]
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_capacity
  max_size                  = var.max_capacity
  health_check_grace_period = 180
  tags                      = local.common_tags
}

########################################
# MONITORING AND ALERTING MODULE
########################################
# Creates CloudWatch log groups and alarms for ASG capacity, ALB health,
# and application-tier metrics with optional SNS notifications.
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix                = local.name_prefix
  asg_name                   = module.asg.asg_name
  asg_min_size               = var.min_capacity
  lb_arn_suffix              = module.alb.lb_arn_suffix
  target_group_arn_suffix    = module.alb.target_group_arn_suffix
  application_log_group_name = local.cloudwatch_application_log_group
  userdata_log_group_name    = local.cloudwatch_userdata_log_group
  alarm_actions              = var.monitoring_alarm_actions
  tags                       = local.common_tags
}
