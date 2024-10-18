
output "subnet_ids" {
  description = "The subnet id's to use for the nuke service"
  value       = module.vpc.public_subnet_ids
}
