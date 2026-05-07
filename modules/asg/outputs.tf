########################################
# AUTO SCALING GROUP MODULE OUTPUTS
########################################
# Exported ASG and scaling policy references

output "asg_name" {
  description = "Auto Scaling Group name."
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN."
  value       = aws_autoscaling_group.this.arn
}

output "cpu_target_tracking_policy_name" {
  description = "Target tracking policy name."
  value       = aws_autoscaling_policy.cpu_target_tracking.name
}
