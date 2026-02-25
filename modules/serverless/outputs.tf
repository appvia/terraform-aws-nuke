
output "lambda_function_arn" {
  description = "The ARN of the Lambda function running aws-nuke"
  value       = module.lambda_function.lambda_function_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function running aws-nuke"
  value       = module.lambda_function.lambda_function_name
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role used by the Lambda function"
  value       = module.lambda_function.lambda_role_arn
}
