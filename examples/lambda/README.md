# Lambda Example

## Introduction

This example demonstrates deploying [aws-nuke](https://ekristen.github.io/aws-nuke/) using the **Lambda (container image)** compute backend via the [terraform-aws-nuke](../../) root module. It provisions a single Lambda function running a dry-run nuke task with SNS notification.

Lambda mode requires a Lambda-compatible wrapper image. See the root [README](../../README.md#lambda-wrapper-image) for build instructions.

## Features

- **Lambda compute backend** -- runs aws-nuke as a container-image Lambda function with configurable architecture (`x86_64` in this example), memory, and timeout.
- **Dry-run with notification** (`dry-run`) -- runs every Monday at 09:00 UTC, reports what would be deleted, and publishes results to an SNS topic.
- **Custom container image** -- the `container_image` variable allows you to point at your own ECR-hosted Lambda wrapper image.

## Usage

```hcl
module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  account_id      = data.aws_caller_identity.current.account_id
  container_image = var.container_image
  region          = data.aws_region.current.name
  tags            = local.tags

  lambda = {
    architecture = "x86_64"
    memory_size  = 256
    timeout      = 900
  }

  tasks = {
    "dry-run" = {
      configuration   = file("${path.module}/assets/nuke-config.yml")
      description     = "Dry run -- reports what would be deleted"
      dry_run         = true
      notifications   = {
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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The container image to use for the Lambda function | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | The subnet id's to use for the nuke service |
<!-- END_TF_DOCS -->