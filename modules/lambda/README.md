# Lambda Sub-module

## Introduction

This sub-module provisions the **Lambda (container image)** compute backend for [aws-nuke](https://ekristen.github.io/aws-nuke/). It is called by the root module when `var.lambda` is set and is not intended to be used directly -- use the [root module](../../) instead.

The upstream aws-nuke container image is **not** Lambda-compatible (it has no Lambda Runtime Interface Client). You must supply a Lambda-compatible wrapper image via `container_image`. A ready-made `Dockerfile` and Python handler are provided in [`assets/docker/`](../../assets/docker/).

## Features

- **Single Lambda function** -- one container-image Lambda function shared across all tasks, reducing infrastructure overhead.
- **EventBridge scheduling** -- one EventBridge scheduled rule per task, each passing a static JSON input payload (`task_name`, `dry_run`, `secret_name`, `sns_topic_arn`).
- **Secrets Manager integration** -- the Lambda handler fetches the nuke YAML configuration from Secrets Manager at invocation time.
- **Optional SNS notifications** -- tasks with `notifications.sns_topic_arn` configured publish a dry-run summary directly to SNS.
- **Union IAM permissions** -- the Lambda execution role receives the union of all task `permission_arns` plus `secretsmanager:GetSecretValue` scoped to the configured secret prefix.
- **Inline and managed IAM policies** -- supports both managed policy ARN attachments and additional inline policies across tasks.
- **Configurable architecture** -- supports `arm64` and `x86_64` Lambda architectures.
- **CloudWatch Logs** -- a managed log group with configurable retention, class, and optional KMS encryption.

## Usage

This module is invoked by the root module. To use the Lambda backend, set the `lambda` variable on the root module:

```hcl
module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  account_id      = data.aws_caller_identity.current.account_id
  container_image = "<account_id>.dkr.ecr.<region>.amazonaws.com/lz/operations/aws-nuke:latest"
  region          = data.aws_region.current.name
  tags            = local.tags

  lambda = {
    architecture = "arm64"
  }

  tasks = {
    "default" = {
      configuration   = file("${path.module}/assets/nuke-config.yml")
      description     = "Weekly nuke run"
      dry_run         = false
      schedule        = "cron(0 10 ? * FRI *)"
      permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }
}
```

## Lambda Wrapper Image

Build and push the wrapper image before applying Lambda mode:

```bash
docker build \
  --build-arg NUKE_TAG=v3.26.0-2-g672408a-amd64 \
  -t <account_id>.dkr.ecr.<region>.amazonaws.com/lz/operations/aws-nuke:latest \
  assets/docker/

docker push <account_id>.dkr.ecr.<region>.amazonaws.com/lz/operations/aws-nuke:latest
```

The handler workflow:

1. Reads the EventBridge input payload: `{task_name, dry_run, secret_name, sns_topic_arn}`
2. Fetches the nuke YAML configuration from Secrets Manager
3. Runs `aws-nuke run` as a subprocess
4. Optionally publishes a dry-run summary to SNS

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account id to use for the resources | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | The class of the CloudWatch log group | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | The KMS key id to use for encrypting the log group | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The retention period for the CloudWatch log group | `number` | n/a | yes |
| <a name="input_configuration_secret_name_prefix"></a> [configuration\_secret\_name\_prefix](#input\_configuration\_secret\_name\_prefix) | The prefix used for AWS Secrets Manager task configuration secrets | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the instance (used to prefix the resources) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to use for the resources | `string` | n/a | yes |
| <a name="input_tasks"></a> [tasks](#input\_tasks) | A collection of nuke tasks to run and when to run them | <pre>map(object({<br/>    # Additional permissions to attach to the task role<br/>    additional_permissions = optional(map(object({<br/>      # The policy to attach to the task role<br/>      policy = string<br/>    })), {})<br/>    # The configuration to use for the task<br/>    configuration = string<br/>    # The description to use for the task<br/>    description = string<br/>    # Indicates if the task should be a dry run (default is true)<br/>    dry_run = optional(bool, true)<br/>    # The notifications to send for the task<br/>    notifications = optional(object({<br/>      # The SNS topic to send the notification to<br/>      sns_topic_arn = optional(string, null)<br/>      }), {<br/>      sns_topic_arn = null<br/>    })<br/>    # The permission ARNs to attach to the task role<br/>    permission_arns = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])<br/>    # The permission boundary to use for the task role<br/>    permission_boundary_arn = optional(string, null)<br/>    # The schedule to run the task<br/>    schedule = string<br/>  }))</pre> | n/a | yes |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | Optional Lambda-compatible container image URI to use for the nuke function (IMAGE:TAG) | `string` | `null` | no |
| <a name="input_lambda_architecture"></a> [lambda\_architecture](#input\_lambda\_architecture) | The architecture to use for the Lambda function | `string` | `"arm64"` | no |
| <a name="input_lambda_log_level"></a> [lambda\_log\_level](#input\_lambda\_log\_level) | The log level to use for the Lambda function | `string` | `"INFO"` | no |
| <a name="input_lambda_memory_size"></a> [lambda\_memory\_size](#input\_lambda\_memory\_size) | The memory size to use for the Lambda function | `number` | `256` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | The timeout to use for the Lambda function | `number` | `900` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | The ARN of the Lambda function running aws-nuke |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | The name of the Lambda function running aws-nuke |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | The ARN of the IAM role used by the Lambda function |
<!-- END_TF_DOCS -->