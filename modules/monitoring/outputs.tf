########################################
# MONITORING MODULE OUTPUTS
########################################
# Exported CloudWatch log groups and alarm names

output "application_log_group_name" {
  description = "CloudWatch log group used for application output."
  value       = aws_cloudwatch_log_group.application.name
}

output "userdata_log_group_name" {
  description = "CloudWatch log group used for user data output."
  value       = aws_cloudwatch_log_group.userdata.name
}

output "alarm_names" {
  description = "Created CloudWatch alarm names."
  value = [
    aws_cloudwatch_metric_alarm.asg_in_service_low.alarm_name,
    aws_cloudwatch_metric_alarm.alb_target_5xx_high.alarm_name,
    aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name,
  ]
}
