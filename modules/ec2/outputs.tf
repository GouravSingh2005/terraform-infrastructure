########################################
# EC2 MODULE OUTPUTS
########################################
# Exported launch template references and AMI IDs

output "launch_template_id" {
  description = "Launch template identifier."
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "Launch template ARN."
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "Latest launch template version."
  value       = aws_launch_template.this.latest_version
}

output "resolved_ami_id" {
  description = "AMI ID used by the launch template."
  value       = local.resolved_ami_id
}
