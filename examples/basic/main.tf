#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  tags = {
    "Environment" = "Sandbox"
    "GitRepo"     = "https://github.com/appvia/terraform-aws-nuke"
    "Owner"       = "Support"
    "Product"     = "Sandbox"
  }
}

module "vpc" {
  source  = "appvia/network/aws"
  version = "0.3.2"

  availability_zones     = 2
  enable_ipam            = false
  enable_transit_gateway = false
  name                   = "nuke"
  public_subnet_netmask  = 28
  tags                   = local.tags
  transit_gateway_id     = null
  vpc_cidr               = "172.16.0.0/25"
}

module "nuke" {
  source = "../../"

  ## Indicates if the KMS key should be created for the log group 
  create_kms_key = false
  ## Indicates if we should skips deletion (default is false)
  enable_deletion = false
  ## This is the location of the aws-nuke configuration file, this is 
  ## copied into the container via a parameter store value
  nuke_configuration = "${path.module}/assets/nuke-config.yml.example"
  ## This will create a task that runs every day at midnight
  schedule_expression = "cron(0 0 * * ? *)"
  ## Name of the secret (AWS Secrets Manager) to store the configuration in 
  configuration_secret_name = "sandbox/nuke"
  ## The ssubnet_ids to use for the nuke service 
  subnet_ids = module.vpc.public_subnet_ids
  ## The tags for the resources created by this module 
  tags = local.tags
}
