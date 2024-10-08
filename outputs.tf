
output "kms_key_id" {
  description = "The KMS key ID used for the nuke service, if created"
  value       = var.create_kms_key ? module.kms[0].key_id : null
}

output "kms_key_arn" {
  description = "The KMS key ARN used for the nuke service, if created"
  value       = var.create_kms_key ? module.kms[0].key_arn : null
}

output "parameter_store_arn" {
  description = "The ARN of the parameter store containing the nuke configuration"
  value       = aws_ssm_parameter.configuration.arn
}

output "private_subnet_id_by_az" {
  description = "The private subnets to use for the nuke service"
  value       = local.private_subnet_id_by_az
}

output "vpc_id" {
  description = "The VPC where the nuke service is running"
  value       = local.vpc_id
}
