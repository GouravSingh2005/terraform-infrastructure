########################################
# USERDATA MODULE OUTPUTS
########################################
# Exported base64-encoded user data script

output "user_data_base64" {
  description = "Base64-encoded user data script for the launch template."
  value       = base64encode(local.rendered_user_data)
}
