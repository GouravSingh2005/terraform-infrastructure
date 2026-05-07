# Root Module Outputs
# These outputs are the primary way consumers of this module access infrastructure details.
# They are also displayed when terraform apply completes and are available to
# terraform output command for scripting and integration purposes.

output "vpc_id" {
  description = "VPC identifier."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet identifiers."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet identifiers."
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet identifiers."
  value       = module.vpc.private_db_subnet_ids
}

# ALB DNS name is used for Route 53 CNAME or Namecheap subdomain mapping.
output "alb_dns_name" {
  description = "DNS name of the internet-facing ALB."
  value       = module.alb.dns_name
}

# Canonical application URL for documentation and testing.
output "application_url" {
  description = "Canonical application URL based on the configured subdomain."
  value       = local.application_url
}

output "asg_name" {
  description = "Auto Scaling Group name for the application tier."
  value       = module.asg.asg_name
}

# Security group IDs organized by tier for reference in other projects.
output "security_group_ids" {
  description = "Security group identifiers for the load balancer, app tier, and database placeholder."
  value = {
    alb = module.security_groups.alb_security_group_id
    app = module.security_groups.app_security_group_id
    db  = module.security_groups.db_security_group_id
  }
}

output "target_group_arn" {
  description = "Application target group ARN."
  value       = module.alb.target_group_arn
}

# ARN suffixes are used by CloudWatch alarms to identify metrics.
output "alb_target_group_arn_suffix" {
  description = "Target group ARN suffix used by monitoring alarms."
  value       = module.alb.target_group_arn_suffix
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix used by monitoring alarms."
  value       = module.alb.lb_arn_suffix
}
