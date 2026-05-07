########################################
# VPC MODULE OUTPUTS
########################################
# Exported values for VPC and subnet resources

output "vpc_id" {
  description = "VPC identifier."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet identifiers."
  value       = [for idx in sort(keys(aws_subnet.public)) : aws_subnet.public[idx].id]
}

output "private_app_subnet_ids" {
  description = "Private application subnet identifiers."
  value       = [for idx in sort(keys(aws_subnet.private_app)) : aws_subnet.private_app[idx].id]
}

output "private_db_subnet_ids" {
  description = "Private database subnet identifiers."
  value       = [for idx in sort(keys(aws_subnet.private_db)) : aws_subnet.private_db[idx].id]
}

output "public_route_table_id" {
  description = "Public route table identifier."
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "Private app route table identifiers."
  value       = [for idx in sort(keys(aws_route_table.private_app)) : aws_route_table.private_app[idx].id]
}

output "private_db_route_table_ids" {
  description = "Private DB route table identifiers."
  value       = [for idx in sort(keys(aws_route_table.private_db)) : aws_route_table.private_db[idx].id]
}
