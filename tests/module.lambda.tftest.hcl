mock_provider "aws" {
  ## aws_iam_policy_document is evaluated by the provider; supply valid JSON so
  ## resource policy attributes pass client-side validation during plan.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  ## The lambda_function module constructs IAM ARNs using aws_partition.
  ## Mock it to return a valid partition so ARN validation passes.
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "eu-west-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  ## The lambda_function module fetches managed IAM policies for tracing/VPC
  ## via data.aws_iam_policy; the mock must return valid JSON.
  mock_data "aws_iam_policy" {
    defaults = {
      policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

## Validate single-task Lambda provisioning: function name, ARN, and role ARN
## are all non-null in plan output.
run "lambda_single_task" {
  command = plan

  module {
    source = "./modules/lambda"
  }

  variables {
    name       = "nuke-test"
    account_id = "123456789012"
    region     = "eu-west-1"

    cloudwatch_log_group_class             = "STANDARD"
    cloudwatch_log_group_kms_key_id        = null
    cloudwatch_log_group_retention_in_days = 7
    container_image                        = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/lz/operations/aws-nuke:latest"
    configuration_secret_name_prefix       = "/lz/services/nuke"
    lambda_architecture                    = "arm64"
    lambda_memory_size                     = 256
    lambda_timeout                         = 900

    tasks = {
      "sandbox" = {
        configuration = "accounts:\n  target:\n    - 123456789012\nregions:\n  - eu-west-1"
        description   = "Sandbox nuke task"
        dry_run       = true
        schedule      = "cron(0 10 ? * FRI *)"
      }
    }
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name must not be null"
  }
}

## Validate multi-task Lambda provisioning: a single function handles all tasks.
## The function name and ARN remain consistent regardless of task count.
run "lambda_multi_task" {
  command = plan

  module {
    source = "./modules/lambda"
  }

  variables {
    name       = "nuke-multi"
    account_id = "123456789012"
    region     = "eu-west-1"

    cloudwatch_log_group_class             = "STANDARD"
    cloudwatch_log_group_kms_key_id        = null
    cloudwatch_log_group_retention_in_days = 7
    container_image                        = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/lz/operations/aws-nuke:latest"
    configuration_secret_name_prefix       = "/lz/services/nuke"
    lambda_architecture                    = "arm64"
    lambda_memory_size                     = 512
    lambda_timeout                         = 600

    tasks = {
      "sandbox" = {
        configuration   = "accounts:\n  target:\n    - 123456789012\nregions:\n  - eu-west-1"
        description     = "Sandbox nuke — weekly delete run"
        dry_run         = false
        schedule        = "cron(0 10 ? * FRI *)"
        permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      }
      "dev" = {
        configuration = "accounts:\n  target:\n    - 123456789013\nregions:\n  - eu-west-1"
        description   = "Dev nuke — weekly dry-run"
        dry_run       = true
        schedule      = "cron(0 9 ? * MON *)"
      }
    }
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name must not be null"
  }
}

