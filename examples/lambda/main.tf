#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Tags to apply to the resources
  tags = {
    "Environment" = "Sandbox"
    "GitRepo"     = "https://github.com/appvia/terraform-aws-nuke"
    "Owner"       = "Support"
    "Product"     = "Sandbox"
  }
  # The account id we are running in
  account_id = data.aws_caller_identity.current.account_id
  # The region we are running in
  region = data.aws_region.current.region
}

module "nuke" {
  source = "../../"

  ## The account id we are running in
  account_id = local.account_id
  ## Indicates if the KMS key should be created for the log group
  create_kms_key = false
  ## The name of the instance (used to prefix all resources)
  name = "nuke-test"
  ## The region to use for the resources
  region = local.region
  ## The tags for the resources created by this module
  tags = local.tags
  ## Configure Lambda as the compute backend.
  lambda = {
    # The architecture to use for the Lambda function
    architecture = "x86_64"
    # The memory size to use for the Lambda function
    memory_size = 256
    # The timeout to use for the Lambda function
    timeout = 900
  }
  # The container image to use for the Lambda function (OVERRIDDEN BY VARIABLE)
  container_image = var.container_image
  # The tasks to run
  tasks = {
    "dry-run" = {
      ## The path to the configuration file for the task
      configuration = templatefile("${path.module}/assets/nuke-config.yml.example", {
        account_id = local.account_id
      })
      ## A description for the task
      description = "Runs a dry run to validate what would be deleted"
      ## Indicates if the task should be a dry run (default is true)
      dry_run = true
      ## The configuration for a notification to be sent
      notifications = {
        ## The SNS topic to send the notification to
        sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:nuke-dry-run"
      }
      ## The schedule expression for the task - every monday at 09:00
      schedule = "cron(0 9 ? * MON *)"
      ## The IAM permissions to attach to the task role
      permission_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
    }
  }
}
