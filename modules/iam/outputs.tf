########################################
# IAM MODULE OUTPUTS
########################################
# Exported IAM role and instance profile references

output "ec2_role_name" {
  description = "IAM role name used by the application instances."
  value       = aws_iam_role.ec2.name
}

output "ec2_role_arn" {
  description = "IAM role ARN used by the application instances."
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "Instance profile name used by the launch template."
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "Instance profile ARN used by the launch template."
  value       = aws_iam_instance_profile.ec2.arn
}
