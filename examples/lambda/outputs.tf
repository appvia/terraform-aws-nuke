
output "kms_key_id" {
  description = "The KMS key ID used for the nuke service, if created"
  value       = module.nuke.kms_key_id
}

output "kms_key_arn" {
  description = "The KMS key ARN used for the nuke service, if created"
  value       = module.nuke.kms_key_arn
}


output "lambda_function_arn" {
  description = "The ARN of the Lambda function running nuke tasks, if serverless mode is enabled"
  value       = module.nuke.lambda_function_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function running nuke tasks, if serverless mode is enabled"
  value       = module.nuke.lambda_function_name
}

output "secret_arns" {
  description = "A map of task name to the ARN of the SecretsManager secret holding the nuke configuration"
  value       = module.nuke.secret_arns
}
