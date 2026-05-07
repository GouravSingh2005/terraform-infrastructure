########################################
# USER DATA SCRIPT RENDERING
########################################
# Renders the bash user data script template with instance-specific variables.
# Script handles package installation, application setup, and logging config.
locals {
  rendered_user_data = templatefile("${path.module}/user_data.sh.tpl", {
    app_name                         = var.app_name
    app_port                         = var.app_port
    aws_region                       = var.aws_region
    cloudwatch_application_log_group = var.cloudwatch_application_log_group
    cloudwatch_userdata_log_group    = var.cloudwatch_userdata_log_group
  })
}
