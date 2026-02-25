# Basic Example (ECS Fargate)

## Introduction

This example demonstrates deploying [aws-nuke](https://ekristen.github.io/aws-nuke/) using the **ECS Fargate** compute backend via the [terraform-aws-nuke](../../) root module. It provisions a VPC, an ECS Fargate cluster, and two scheduled nuke tasks.

## Features

- **Destructive run** (`default`) -- runs every Friday at 10:00 UTC with `dry_run = false`, deleting matching resources with `AdministratorAccess`.
- **Dry-run with notification** (`dry-run`) -- runs every Monday at 09:00 UTC with `dry_run = true` and publishes a summary to an SNS topic using `ReadOnlyAccess`.
- **Switchable backend** -- comment out the `ecs` block and uncomment the `lambda` block in `main.tf` to use Lambda mode instead. Lambda mode requires a Lambda-compatible wrapper image (see the root [README](../../README.md#lambda-wrapper-image)).

## Usage

```hcl
module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  tags       = local.tags

  ecs = {
    subnet_ids = module.vpc.public_subnet_ids
  }

  tasks = {
    "default" = {
      configuration   = file("${path.module}/assets/nuke-config.yml")
      description     = "Weekly nuke run -- deletes sandbox resources"
      dry_run         = false
      schedule        = "cron(0 10 ? * FRI *)"
      permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }

    "dry-run" = {
      configuration = file("${path.module}/assets/nuke-config.yml")
      description   = "Weekly dry run -- reports what would be deleted"
      dry_run       = true
      notifications = {
        sns_topic_arn = "arn:aws:sns:eu-west-1:123456789012:nuke-dry-run"
      }
      schedule        = "cron(0 9 ? * MON *)"
      permission_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | The subnet id's to use for the nuke service |
<!-- END_TF_DOCS -->