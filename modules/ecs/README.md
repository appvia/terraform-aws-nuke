# ECS Sub-module

## Introduction

This sub-module provisions the **ECS Fargate** compute backend for [aws-nuke](https://ekristen.github.io/aws-nuke/). It is called by the root module when `var.ecs` is set and is not intended to be used directly -- use the [root module](../../) instead.

The nuke YAML configuration for each task is stored in AWS Secrets Manager by the root module and injected into the container via the `NUKE_CONFIG` environment variable at runtime.

## Features

- **ECS Fargate cluster** -- a dedicated cluster is provisioned to run aws-nuke tasks.
- **Per-task resources** -- each task receives its own ECS task definition, IAM execution role (ECR pull + CloudWatch Logs), IAM task role (configurable `permission_arns`), and CloudWatch log group.
- **EventBridge scheduling** -- one EventBridge scheduled rule per task triggers the Fargate task on a cron expression.
- **Optional SNS notifications** -- tasks with `notifications.sns_topic_arn` set receive a Lambda function that fires on ECS task state change (`STOPPED`) and publishes a summary to SNS.
- **Inline and managed IAM policies** -- supports both managed policy ARN attachments and additional inline policies per task.
- **Permission boundaries** -- optional per-task permission boundary support.
- **Container Insights** -- optionally enable ECS Container Insights on the cluster.

## Usage

This module is invoked by the root module. To use the ECS backend, set the `ecs` variable on the root module:

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
      description     = "Weekly nuke run"
      dry_run         = false
      schedule        = "cron(0 10 ? * FRI *)"
      permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account id to use for the resources | `string` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Indicates if the task should be assigned a public IP | `bool` | n/a | yes |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | The class of the CloudWatch log group | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | The KMS key id to use for encrypting the log group | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_prefix"></a> [cloudwatch\_log\_group\_prefix](#input\_cloudwatch\_log\_group\_prefix) | The prefix to use for the CloudWatch log group | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The retention period for the CloudWatch log group | `number` | n/a | yes |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | The amount of CPU to allocate to the container | `number` | n/a | yes |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The image to use for the container | `string` | n/a | yes |
| <a name="input_container_image_tag"></a> [container\_image\_tag](#input\_container\_image\_tag) | The tag to use for the container image | `string` | n/a | yes |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | The amount of memory to allocate to the container | `number` | n/a | yes |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Indicates if container insights should be enabled for the cluster | `bool` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the instance (used to prefix the resources) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to use for the resources | `string` | n/a | yes |
| <a name="input_secret_arns"></a> [secret\_arns](#input\_secret\_arns) | A map of task name to the ARN of the SecretsManager secret holding the nuke configuration | `map(string)` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnet id's to use for the nuke service | `list(string)` | n/a | yes |
| <a name="input_tasks"></a> [tasks](#input\_tasks) | A collection of nuke tasks to run and when to run them | <pre>map(object({<br/>    # Additional permissions to attach to the task role<br/>    additional_permissions = optional(map(object({<br/>      # The policy to attach to the task role<br/>      policy = string<br/>    })), {})<br/>    # The configuration to use for the task<br/>    configuration = string<br/>    # The description to use for the task<br/>    description = string<br/>    # Indicates if the task should be a dry run (default is true)<br/>    dry_run = optional(bool, true)<br/>    # The notifications to send for the task<br/>    notifications = optional(object({<br/>      # The SNS topic to send the notification to<br/>      sns_topic_arn = optional(string, null)<br/>      }), {<br/>      sns_topic_arn = null<br/>    })<br/>    # The permission boundary to use for the task role<br/>    permission_boundary_arn = optional(string, null)<br/>    # The permission ARNs to attach to the task role<br/>    permission_arns = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])<br/>    # The schedule to run the task<br/>    schedule = string<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | The ARN of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | The name of the ECS cluster |
<!-- END_TF_DOCS -->