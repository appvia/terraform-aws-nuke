
output "repository_arn" {
  description = "The ARN of the ECR repository for the nuke container"
  value       = aws_ecr_repository.nuke.arn
}

output "repository_name" {
  description = "The name of the ECR repository for the nuke container"
  value       = aws_ecr_repository.nuke.name
}