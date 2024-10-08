
output "kms_key_id" {
  description = "The KMS key ID used for the nuke service, if created"
  value       = var.create_kms_key ? module.kms[0].key_id : null
}

output "kms_key_arn" {
  description = "The KMS key ARN used for the nuke service, if created"
  value       = var.create_kms_key ? module.kms[0].key_arn : null
}

output "secret_arn" {
  description = "The ARN of the AWS Secrets Manager containing the nuke configuration"
  value       = aws_secretsmanager_secret.configuration.arn
}

output "secret_arn_id" {
  description = "The ID of the AWS Secrets Manager containing the nuke configuration"
  value       = aws_secretsmanager_secret.configuration.id
}
