
mock_provider "aws" {
  ## aws_iam_policy_document is computed by the provider; mock with valid JSON
  ## so resource policy attributes pass client-side validation during plan.
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

## Validate ECS Fargate mode: cluster is provisioned, Lambda outputs are null.
run "ecs_mode" {
  command = plan

  variables {
    name       = "nuke-test"
    account_id = "123456789012"
    region     = "eu-west-1"

    ecs = {
      subnet_ids = ["subnet-12345678", "subnet-87654321"]
    }

    tasks = {
      "sandbox" = {
        configuration = file("./examples/basic/assets/nuke-config.yml.example")
        description   = "Sandbox nuke task"
        dry_run       = true
        schedule      = "cron(0 10 ? * FRI *)"
      }
    }
  }

  assert {
    condition     = output.ecs_cluster_name != null
    error_message = "ECS cluster name must be set when ecs is configured"
  }

  assert {
    condition     = output.lambda_function_name == null
    error_message = "Lambda function name must be null when only ECS is configured"
  }

  assert {
    condition     = output.kms_key_id == null
    error_message = "KMS key must not be created when create_kms_key is false"
  }
}

## Validate Lambda mode: function is provisioned, ECS outputs are null.
run "lambda_mode" {
  command = plan

  variables {
    name       = "nuke-test"
    account_id = "123456789012"
    region     = "eu-west-1"

    lambda = {
      architecture = "arm64"
    }

    tasks = {
      "sandbox" = {
        configuration = file("./examples/basic/assets/nuke-config.yml.example")
        description   = "Sandbox nuke task"
        dry_run       = true
        schedule      = "cron(0 10 ? * FRI *)"
      }
    }
  }

  assert {
    condition     = output.ecs_cluster_name == null
    error_message = "ECS cluster name must be null when only Lambda is configured"
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name must be set when lambda is configured"
  }
}

## Validate KMS key creation: the plan succeeds without error when create_kms_key = true
## and the ECS cluster is still provisioned correctly.
run "kms_enabled" {
  command = plan

  variables {
    name           = "nuke-test"
    account_id     = "123456789012"
    region         = "eu-west-1"
    create_kms_key = true

    ecs = {
      subnet_ids = ["subnet-12345678"]
    }

    tasks = {
      "sandbox" = {
        configuration = file("./examples/basic/assets/nuke-config.yml.example")
        description   = "Sandbox nuke task"
        dry_run       = true
        schedule      = "cron(0 10 ? * FRI *)"
      }
    }
  }

  ## KMS key ID/ARN are computed by the provider so they're unknown during plan.
  ## Assert on the ECS cluster (known at plan time) to confirm the module
  ## still plans successfully with create_kms_key = true.
  assert {
    condition     = output.ecs_cluster_name != null
    error_message = "ECS cluster name must be set even when KMS key is enabled"
  }
}

## Validate dual mode: both ECS and Lambda can be active simultaneously.
run "dual_mode" {
  command = plan

  variables {
    name       = "nuke-test"
    account_id = "123456789012"
    region     = "eu-west-1"

    ecs = {
      subnet_ids = ["subnet-12345678"]
    }

    lambda = {
      architecture = "arm64"
    }

    tasks = {
      "sandbox" = {
        configuration = file("./examples/basic/assets/nuke-config.yml.example")
        description   = "Sandbox nuke task"
        dry_run       = true
        schedule      = "cron(0 10 ? * FRI *)"
      }
    }
  }

  assert {
    condition     = output.ecs_cluster_name != null
    error_message = "ECS cluster name must be set in dual mode"
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name must be set in dual mode"
  }
}
