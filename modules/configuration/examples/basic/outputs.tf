
output "configuration" {
  description = "The rendered configuration file for the nuke service"
  value       = module.configuration.configuration
}
