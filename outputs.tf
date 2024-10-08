
output "vpc_id" {
  description = "The VPC where the nuke service is running"
  value       = local.vpc_id
}

output "private_subnet_id_by_az" {
  description = "The private subnets to use for the nuke service"
  value       = local.private_subnet_id_by_az
}
