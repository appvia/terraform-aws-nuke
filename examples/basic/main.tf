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

data "aws_iam_policy_document" "additional" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
    effect    = "Allow"
  }
}

module "nuke" {
  source = "../../"

  ## The account id we are running in
  account_id = data.aws_caller_identity.current.account_id
  ## Indicates if the KMS key should be created for the log group 
  create_kms_key = false
  ## The region to use for the resources 
  region = data.aws_region.current.name
  ## The ssubnet_ids to use for the nuke service 
  subnet_ids = module.vpc.public_subnet_ids
  ## The tags for the resources created by this module 
  tags = local.tags
  ## name is the service name 
  ecs_cluster_name = "nuke-example"

  tasks = {
    "default" = {
      ## The path to the configuration file for the task
      configuration_file = "${path.module}/assets/nuke-config.yml.example"
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
      ## Additional inline permissions 
      additional_permissions = {
        "secrets" = {
          policy = data.aws_iam_policy_document.additional.json
        }
      }
    }

    "dry-run" = {
      ## The path to the configuration file for the task
      configuration_file = "${path.module}/assets/nuke-config.yml.example"
      ## A description for the task 
      description = "Runs a dry run to validate what would be deleted"
      ## Indicates if the task should be a dry run (default is true)
      dry_run = true
      ## The log retention in days for the task 
      retention_in_days = 7
      ## The schedule expression for the task - every monday at 09:00
      schedule = "cron(0 9 ? * MON *)"
      ## The IAM permissions to attach to the task role 
      permission_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      ## Additional inline permissions 
      additional_permissions = {
        "secrets" = {
          policy = data.aws_iam_policy_document.additional.json
        }
      }
    }
  }
}
