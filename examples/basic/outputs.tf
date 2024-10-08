
output "secret_arn" {
  description = "The ARN of the secret containing the nuke configuration"
  value       = module.nuke.secret_arn
}

output "subnet_ids" {
  description = "The subnet id's to use for the nuke service"
  value       = module.vpc.public_subnet_ids
}
