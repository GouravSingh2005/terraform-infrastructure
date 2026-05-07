########################################
# APPLICATION LOG GROUP
########################################
# CloudWatch log group for application output from EC2 instances.
resource "aws_cloudwatch_log_group" "application" {
  name              = var.application_log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

########################################
# USER DATA LOG GROUP
########################################
# CloudWatch log group for bootstrap/user data logs from EC2 instances.
resource "aws_cloudwatch_log_group" "userdata" {
  name              = var.userdata_log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

########################################
# ASG IN-SERVICE CAPACITY ALARM
########################################
# Alerts when ASG has fewer healthy instances than configured minimum.
resource "aws_cloudwatch_metric_alarm" "asg_in_service_low" {
  alarm_name          = "${var.name_prefix}-asg-in-service-low"
  alarm_description   = "Alerts when the Auto Scaling Group has fewer in-service instances than expected."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = var.asg_min_size
  treat_missing_data  = "breaching"
  statistic           = "Average"
  period              = 300
  namespace           = "AWS/AutoScaling"
  metric_name         = "GroupInServiceInstances"
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}

########################################
# ALB TARGET 5XX ERROR ALARM
########################################
# Alerts when target group returns elevated HTTP 5xx errors.
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx_high" {
  alarm_name          = "${var.name_prefix}-alb-target-5xx-high"
  alarm_description   = "Alerts when the target group returns elevated 5xx errors."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 10
  treat_missing_data  = "notBreaching"
  statistic           = "Sum"
  period              = 300
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions = {
    LoadBalancer = var.lb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}

########################################
# ALB UNHEALTHY HOSTS ALARM
########################################
# Alerts when target group reports unhealthy instances.
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-alb-unhealthy-hosts"
  alarm_description   = "Alerts when the target group reports unhealthy hosts."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 0
  treat_missing_data  = "notBreaching"
  statistic           = "Average"
  period              = 300
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions = {
    LoadBalancer = var.lb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = var.tags
}
