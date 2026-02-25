
output "kms_key_id" {
  description = "The KMS key ID used for the nuke service, if created"
  value       = var.create_kms_key ? module.kms[0].key_id : null
}

output "kms_key_arn" {
  description = "The KMS key ARN used for the nuke service, if created"
  value       = var.create_kms_key ? module.kms[0].key_arn : null
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster running nuke tasks, if ECS mode is enabled"
  value       = var.ecs != null ? module.ecs_nuke[0].ecs_cluster_arn : null
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster running nuke tasks, if ECS mode is enabled"
  value       = var.ecs != null ? module.ecs_nuke[0].ecs_cluster_name : null
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function running nuke tasks, if serverless mode is enabled"
  value       = var.lambda != null ? module.lambda_nuke[0].lambda_function_arn : null
}

output "lambda_function_name" {
  description = "The name of the Lambda function running nuke tasks, if serverless mode is enabled"
  value       = var.lambda != null ? module.lambda_nuke[0].lambda_function_name : null
}

output "secret_arns" {
  description = "A map of task name to the ARN of the SecretsManager secret holding the nuke configuration"
  value       = local.secret_arns
}
