
output "parameter_store_arn" {
  description = "The ARN of the parameter store containing the nuke configuration"
  value       = module.nuke.parameter_store_arn
}
