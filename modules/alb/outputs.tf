########################################
# ALB MODULE OUTPUTS
########################################
# Exported ALB and target group resource references

output "dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "ALB hosted zone ID."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix."
  value       = aws_lb_target_group.this.arn_suffix
}

output "lb_arn" {
  description = "ALB ARN."
  value       = aws_lb.this.arn
}

output "lb_arn_suffix" {
  description = "ALB ARN suffix."
  value       = aws_lb.this.arn_suffix
}
