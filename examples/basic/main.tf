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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source  = "appvia/network/aws"
  version = "0.6.10"

  availability_zones    = 2
  name                  = "nuke"
  public_subnet_netmask = 28
  tags                  = local.tags
  transit_gateway_id    = null
  vpc_cidr              = "172.16.0.0/25"

}

module "nuke" {
  source = "../../"

  ## The account id we are running in
  account_id = data.aws_caller_identity.current.account_id
  ## Indicates if the KMS key should be created for the log group
  create_kms_key = false
  ## The name of the instance (used to prefix all resources)
  name = "nuke-example"
  ## The region to use for the resources
  region = data.aws_region.current.name
  ## The tags for the resources created by this module
  tags = local.tags

  ## Configure ECS Fargate as the compute backend.
  ## Set to null to disable ECS and use Lambda instead (see lambda variable).
  ecs = {
    subnet_ids = module.vpc.public_subnet_ids
  }

  ## Uncomment to use Lambda as the compute backend instead of ECS.
  ## Requires a Lambda-compatible container image (see container_image variable).
  # lambda = {
  #   architecture = "arm64"
  # }

  tasks = {
    "default" = {
      ## The path to the configuration file for the task
      configuration = file("${path.module}/assets/nuke-config.yml.example")
      ## A description for the task
      description = "Runs the actual nuke service, deleting resources"
      ## Indicates if the task should be a dry run (default is true)
      dry_run = false
      ## The log retention in days for the task
      retention_in_days = 7
      ## The schedule expression for the task, every friday at 10:00
      schedule = "cron(0 10 ? * FRI *)"
      ## The IAM permissions to attach to the task role
      permission_arns = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
    }

    "dry-run" = {
      ## The path to the configuration file for the task
      configuration = file("${path.module}/assets/nuke-config.yml.example")
      ## A description for the task
      description = "Runs a dry run to validate what would be deleted"
      ## Indicates if the task should be a dry run (default is true)
      dry_run = true
      ## The configuration for a notification to be sent
      notifications = {
        ## The SNS topic to send the notification to
        sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:nuke-dry-run"
      }
      ## The log retention in days for the task
      retention_in_days = 7
      ## The schedule expression for the task - every monday at 09:00
      schedule = "cron(0 9 ? * MON *)"
      ## The IAM permissions to attach to the task role
      permission_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
    }
  }
}
