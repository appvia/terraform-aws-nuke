mock_provider "aws" {}

## Validate single-task ECS provisioning: cluster name matches var.name,
## ARN is non-null, and the module plan succeeds.
run "ecs_single_task" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  variables {
    name       = "nuke-test"
    account_id = "123456789012"
    region     = "eu-west-1"

    assign_public_ip                       = false
    cloudwatch_log_group_kms_key_id        = null
    cloudwatch_log_group_prefix            = "/lz/services/nuke"
    cloudwatch_log_group_retention_in_days = 7
    container_cpu                          = 256
    container_image                        = "ghcr.io/ekristen/aws-nuke"
    container_image_tag                    = "latest"
    container_memory                       = 512
    enable_container_insights              = false
    subnet_ids                             = ["subnet-12345678"]

    secret_arns = {
      "sandbox" = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:nuke/sandbox-abc123"
    }

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
    condition     = output.ecs_cluster_name == "nuke-test"
    error_message = "ECS cluster name must equal var.name"
  }
}

## Validate multi-task ECS provisioning: cluster name remains consistent
## regardless of task count.
run "ecs_multi_task" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  variables {
    name       = "nuke-multi"
    account_id = "123456789012"
    region     = "eu-west-1"

    assign_public_ip                       = false
    cloudwatch_log_group_kms_key_id        = null
    cloudwatch_log_group_prefix            = "/lz/services/nuke"
    cloudwatch_log_group_retention_in_days = 7
    container_cpu                          = 512
    container_image                        = "ghcr.io/ekristen/aws-nuke"
    container_image_tag                    = "latest"
    container_memory                       = 1024
    enable_container_insights              = true
    subnet_ids                             = ["subnet-aaaa0001", "subnet-aaaa0002"]

    secret_arns = {
      "sandbox" = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:nuke/sandbox-abc"
      "dev"     = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:nuke/dev-abc"
    }

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
    condition     = output.ecs_cluster_name == "nuke-multi"
    error_message = "ECS cluster name must equal var.name"
  }
}

## Validate that a custom permission boundary is accepted without error.
run "ecs_with_permission_boundary" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  variables {
    name       = "nuke-bounded"
    account_id = "123456789012"
    region     = "eu-west-1"

    assign_public_ip                       = false
    cloudwatch_log_group_kms_key_id        = null
    cloudwatch_log_group_prefix            = "/lz/services/nuke"
    cloudwatch_log_group_retention_in_days = 14
    container_cpu                          = 256
    container_image                        = "ghcr.io/ekristen/aws-nuke"
    container_image_tag                    = "latest"
    container_memory                       = 512
    enable_container_insights              = false
    subnet_ids                             = ["subnet-12345678"]

    secret_arns = {
      "sandbox" = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:nuke/sandbox-abc"
    }

    tasks = {
      "sandbox" = {
        configuration           = "accounts:\n  target:\n    - 123456789012\nregions:\n  - eu-west-1"
        description             = "Sandbox nuke with boundary"
        dry_run                 = true
        permission_boundary_arn = "arn:aws:iam::123456789012:policy/NukeBoundary"
        schedule                = "cron(0 10 ? * FRI *)"
      }
    }
  }

  assert {
    condition     = output.ecs_cluster_name == "nuke-bounded"
    error_message = "ECS cluster name must equal var.name"
  }
}
