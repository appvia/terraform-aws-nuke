#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

module "nuke" {
  source = "../../"

  create_kms_key = false
  enabled        = true

  ## This is the location of the aws-nuke configuration file, this is 
  ## copied into the container via a parameter store value
  nuke_configuration = file("${path.module}/assets/nuke-config.yml.example")

  ## This will create a task that runs every day at midnight
  schedule_expression = "cron(0 0 * * ? *)"

  tags = {
    "Environment" = "Testing"
    "GitRepo"     = "https://github.com/appvia/terraform-aws-nuke"
    "Owner"       = "Testing"
    "Product"     = "Terraform AWS Nuke"
  }

  ## This will create an VPC called 'nuke' with 2 availability zones 
  ## and a private netmask of 28
  network = {
    name               = "nuke"
    availability_zones = 2
    private_netmask    = 28
    vpc_cidr           = "172.16.0.0/25"
  }
}
