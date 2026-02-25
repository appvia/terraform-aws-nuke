<!-- markdownlint-disable -->
<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-nuke/blob/main/docs/banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/nuke/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-nuke/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-nuke.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-nuke/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-nuke.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-nuke/actions/workflows/terraform.yml/badge.svg)

# Terraform Nuke Module

## Introduction

The purpose of this module is to provide a method of automated cleanup of AWS resources, using the [aws-nuke](https://ekristen.github.io/aws-nuke/) tool. It schedules periodic nuke runs to clean up resources that are no longer needed in non-production accounts (development, sandbox, testing).

The module supports two compute backends -- choose one or run both simultaneously:

- **ECS Fargate** (`var.ecs`): Runs aws-nuke as a Fargate task. Uses the upstream aws-nuke container image directly.
- **Lambda** (`var.lambda`): Runs aws-nuke as a container-image Lambda function. Requires a Lambda-compatible wrapper image -- see [Lambda Wrapper Image](#lambda-wrapper-image) below.

Each compute backend accepts a `tasks` map where each entry defines a separate nuke configuration, schedule, and IAM permissions. Secrets Manager stores the nuke YAML configuration for each task.

## Features

- **Dual compute backends** -- ECS Fargate and/or Lambda, selectable via simple feature flags.
- **Multi-task scheduling** -- define multiple independent nuke tasks, each with its own configuration, cron schedule, and IAM permissions.
- **Safe by default** -- tasks default to `dry_run = true`; destructive runs require explicit opt-in.
- **Configuration helper module** -- the bundled [`modules/configuration`](./modules/configuration) module renders aws-nuke YAML with built-in filters for Control Tower, Landing Zone Accelerator, AWS managed services, and Cost Intelligence Dashboard resources.
- **ECR repository module** -- the [`modules/repository`](./modules/repository) module provisions a private ECR repository with cross-account and organization-wide pull policies for the Lambda wrapper image.
- **SNS notifications** -- optional per-task completion notifications via SNS (ECS triggers a Lambda notifier on task stop; Lambda publishes directly).
- **KMS encryption** -- optional KMS key creation for CloudWatch log group encryption.
- **Secrets Manager integration** -- nuke configuration YAML is stored securely and injected at runtime.
- **Customisable IAM** -- per-task managed policy attachments, inline policies, and permission boundaries.

## Usage

### ECS Fargate mode

```hcl
module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  tags       = local.tags

  ## Configure ECS Fargate as the compute backend
  ecs = {
    subnet_ids = module.vpc.public_subnet_ids
  }

  tasks = {
    "default" = {
      configuration = file("${path.module}/assets/nuke-config.yml")
      description   = "Weekly nuke run — deletes sandbox resources"
      dry_run       = false
      schedule      = "cron(0 10 ? * FRI *)"
      permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }
}
```

### Lambda mode

Lambda mode requires a Lambda-compatible container image (see [Lambda Wrapper Image](#lambda-wrapper-image)).

```hcl
module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  account_id      = data.aws_caller_identity.current.account_id
  container_image = "<account_id>.dkr.ecr.<region>.amazonaws.com/lz/operations/aws-nuke:latest"
  region          = data.aws_region.current.name
  tags            = local.tags

  ## Configure Lambda as the compute backend
  lambda = {
    architecture = "arm64"
  }

  tasks = {
    "default" = {
      configuration = file("${path.module}/assets/nuke-config.yml")
      description   = "Weekly nuke run — deletes sandbox resources"
      dry_run       = false
      schedule      = "cron(0 10 ? * FRI *)"
      permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }
}
```

## Lambda Wrapper Image

The upstream [aws-nuke](https://github.com/ekristen/aws-nuke) image is **not** Lambda-compatible (it has no Lambda Runtime Interface Client). For Lambda mode you must build and push a wrapper image.

A ready-made `Dockerfile` and Python handler (`handler.py`) are provided in [`assets/docker/`](./assets/docker/). Build and push with:

You can change the defaults using environment variables:

| Name | Description | Default |
|------|-------------|---------|
| `DOCKER_IMAGE` | ECR repository path/name for the Lambda-compatible wrapper image that is built and pushed. | `ACCOUNT.dkr.ecr.eu-west-2.amazonaws.com/lz/rebuy/aws-nuke` |
| `DOCKER_PLATFORM` | The architecture to use for the docker iamge | `linux/amd64` |
| `NUKE_IMAGE` | Source aws-nuke container image used as the base for the Lambda-compatible wrapper image build. | `ghcr.io/ekristen/aws-nuke` |
| `NUKE_TAG` | Tag of the source aws-nuke image used in the wrapper image build. | `v3.26.0-2-g672408a-amd64` |

```bash
# The tag of of the image will be the same as the NUKE_TAG
make docker-ecr-image
```

And to push the image 

```bash 
make docker-ecr-image-push
```

If you prefer not to use the Terraform repository sub-module, you can create and configure the ECR repository manually with the AWS CLI.

### Manual ECR repository setup (AWS CLI)

```bash
export AWS_ECR_REGION="eu-west-2"
export AWS_ACCOUNT_ID="<your-account-id>"
export REPOSITORY_NAME="lz/operations/aws-nuke"

aws ecr create-repository \
  --region "${AWS_ECR_REGION}" \
  --repository-name "${REPOSITORY_NAME}"
```

Create a policy file (for example `ecr-policy.json`) to allow pull access from all accounts in your AWS Organization:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOrgPullAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-7u80c4XXXX"
        }
      }
    },
    {
      "Sid": "AllowLambdaServiceImageRetrieval",
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Condition": {
        "StringLike": {
          "aws:sourceArn": "arn:aws:lambda:eu-west-2:*:function:*"
        }
      }
    }
  ]
}
```

Apply the repository policy:

```bash
aws ecr set-repository-policy \
  --region "${AWS_ECR_REGION}" \
  --repository-name "${REPOSITORY_NAME}" \
  --policy-text file://ecr-policy.json
```

Build and push the Lambda wrapper image while overriding `DOCKER_IMAGE`:

```bash
DOCKER_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_ECR_REGION}.amazonaws.com/${REPOSITORY_NAME}" make docker-ecr-image-push
```

Use the [`modules/repository`](./modules/repository) sub-module to provision the ECR repository:

```hcl
module "nuke_ecr" {
  source = "github.com/appvia/terraform-aws-nuke//modules/repository?ref=main"

  repository_name = "lz/operations/aws-nuke"
  account_ids     = ["123456789012"]
  tags            = local.tags
}
```



## Examples

- [Basic (ECS Fargate)](./examples/basic) -- deploys aws-nuke with ECS Fargate, including a destructive run and a dry-run with SNS notification.
- [Lambda](./examples/lambda) -- deploys aws-nuke with a Lambda container-image backend.

## Configuration Module

The repository also includes a helper [configuration](./modules/configuration) module that renders a nuke configuration file. An example of how to use the module:

```hcl
module "configuration" {
  source = "github.com/appvia/terraform-aws-nuke//modules/configuration?ref=main"

  accounts = ["123456789012", "123456789013"]
  regions  = ["us-east-1", "us-west-2"]

  filters = [
    {
      property = "tag:Environment"
      type     = "string"
      value    = "Sandbox"
    }
  ]
}

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
      configuration   = module.configuration.configuration
      description     = "Weekly nuke run"
      dry_run         = false
      schedule        = "cron(0 10 ? * FRI *)"
      permission_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
  }
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account id to use for the resources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to use for the resources | `string` | n/a | yes |
| <a name="input_tasks"></a> [tasks](#input\_tasks) | A collection of nuke tasks to run and when to run them | <pre>map(object({<br/>    # Additional permissions to attach to the task role<br/>    additional_permissions = optional(map(object({<br/>      # The policy to attach to the task role<br/>      policy = string<br/>    })), {})<br/>    # The configuration to use for the task<br/>    configuration = string<br/>    # The description to use for the task<br/>    description = string<br/>    # Indicates if the task should be a dry run (default is true)<br/>    dry_run = optional(bool, true)<br/>    # The notifications to send for the task<br/>    notifications = optional(object({<br/>      # The SNS topic to send the notification to<br/>      sns_topic_arn = optional(string, null)<br/>      }), {<br/>      sns_topic_arn = null<br/>    })<br/>    # The permission boundary to use for the task role<br/>    permission_boundary_arn = optional(string, null)<br/>    # The permission ARNs to attach to the task role<br/>    permission_arns = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])<br/>    # The retention in days for the log group<br/>    retention_in_days = optional(number, 7)<br/>    # The schedule to run the task<br/>    schedule = string<br/>  }))</pre> | n/a | yes |
| <a name="input_configuration_secret_name_prefix"></a> [configuration\_secret\_name\_prefix](#input\_configuration\_secret\_name\_prefix) | The prefix to use for AWS Secrets Manager secrets to store the nuke configuration | `string` | `"/lz/services/nuke"` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The image to use for the container | `string` | `"ghcr.io/ekristen/aws-nuke"` | no |
| <a name="input_container_image_tag"></a> [container\_image\_tag](#input\_container\_image\_tag) | The tag to use for the container image | `string` | `"v3.26.0-2-g672408a-amd64"` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Indicates if a KMS key should be created for the log group | `bool` | `false` | no |
| <a name="input_ecs"></a> [ecs](#input\_ecs) | Indicates if the ECS cluster should be created | <pre>object({<br/>    ## Associate a public IP address to the task<br/>    assign_public_ip = optional(bool, false)<br/>    ## The prefix to use for the CloudWatch log group<br/>    cloudwatch_log_group_prefix = optional(string, "/lz/services/nuke")<br/>    ## The retention period for the CloudWatch log group (in days)<br/>    cloudwatch_log_group_retention_in_days = optional(number, 7)<br/>    ## The class of the CloudWatch log group<br/>    cloudwatch_log_group_class = optional(string, "STANDARD")<br/>    ## The KMS key id to use for encrypting the log group<br/>    cloudwatch_log_group_kms_key_id = optional(string, null)<br/>    ## The amount of memory to allocate to the container<br/>    container_memory = optional(number, 512)<br/>    ## The amount of CPU to allocate to the container<br/>    container_cpu = optional(number, 256)<br/>    ## Enable container insights<br/>    enable_container_insights = optional(bool, false)<br/>    ## The subnet ids to use for the ECS cluster<br/>    subnet_ids = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_kms_administrator_role_name"></a> [kms\_administrator\_role\_name](#input\_kms\_administrator\_role\_name) | The name of the role to use as the administrator for the KMS key (defaults to account root) | `string` | `""` | no |
| <a name="input_lambda"></a> [lambda](#input\_lambda) | Indicates if the Lambda function should be created | <pre>object({<br/>    # The architecture to use for the Lambda function<br/>    architecture = optional(string, "arm64")<br/>    # The memory size to use for the Lambda function<br/>    memory_size = optional(number, 256)<br/>    # The timeout to use for the Lambda function<br/>    timeout = optional(number, 900)<br/>    ## The cloudwatch log group retention in days<br/>    cloudwatch_log_group_retention_in_days = optional(number, 7)<br/>    ## The cloudwatch log group class<br/>    cloudwatch_log_group_class = optional(string, "STANDARD")<br/>    ## The cloudwatch log group KMS key id<br/>    cloudwatch_log_group_kms_key_id = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the instance (used to prefix the resources) | `string` | `"lz-nuke"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | The ARN of the ECS cluster running nuke tasks, if ECS mode is enabled |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | The name of the ECS cluster running nuke tasks, if ECS mode is enabled |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The KMS key ARN used for the nuke service, if created |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The KMS key ID used for the nuke service, if created |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | The ARN of the Lambda function running nuke tasks, if serverless mode is enabled |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | The name of the Lambda function running nuke tasks, if serverless mode is enabled |
<!-- END_TF_DOCS -->
