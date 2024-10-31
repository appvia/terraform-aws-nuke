<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="./docs/banner.jpg" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/nuke/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-nuke/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-nuke.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-nuke/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-nuke.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](../../actions/workflows/terraform.yml/badge.svg)

# Terraform Nuke Module

## Description

The purpose of this module is to provide a method of automated cleanup of resources, using the [aws-nuke](https://ekristen.github.io/aws-nuke/) tool. This module will create a scheduled task that will run an ECS task on a regular basis to clean up resources that are no longer needed.

It is intended to be used in a non-production environment, such as a development or testing account, to ensure that resources are not left running and incurring costs when they are no longer needed.

## Usage

The following provides an example of how to use this module:

```hcl
locals {
  tags = {
    "Environment" = "Sandbox"
    "GitRepo"     = "https://github.com/appvia/terraform-aws-nuke"
    "Owner"       = "Support"
    "Product"     = "Sandbox"
  }
}

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

module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  ## Indicates if the KMS key should be created for the log group
  create_kms_key = false
  ## Indicates if we should skips deletion (default is false)
  enable_deletion = false
  ## This is the location of the aws-nuke configuration file, this is
  ## copied into the container via a parameter store value
  nuke_configuration = "${path.module}/assets/nuke-config.yml.example"
  ## This will create a task that runs every day at midnight
  schedule_expression = "cron(0 0 * * ? *)"
  ## Name of the secret (AWS Secrets Manager) to store the configuration in
  configuration_secret_name = "sandbox/nuke"
  ## The ssubnet_ids to use for the nuke service
  subnet_ids = module.vpc.public_subnet_ids
  ## The tags for the resources created by this module
  tags = local.tags
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 5.70.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 5.70.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-aws-modules/kms/aws | 3.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.tasks](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.tasks](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.tasks](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.current](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ecs_cluster) | resource |
| [aws_ecs_task_definition.tasks](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.execution_secrets](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_additional_permissions](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.execution](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_permissions_arns](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.configuration](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.configuration](https://registry.terraform.io/providers/hashicorp/aws/5.70.0/docs/resources/secretsmanager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account id to use for the resources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to use for the resources | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnet id's to use for the nuke service | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources created by this module | `map(string)` | n/a | yes |
| <a name="input_tasks"></a> [tasks](#input\_tasks) | A collection of nuke tasks to run and when to run them | <pre>map(object({<br/>    additional_permissions = optional(map(object({<br/>      policy = string<br/>    })), {})<br/>    configuration           = string<br/>    description             = string<br/>    dry_run                 = optional(bool, true)<br/>    permission_boundary_arn = optional(string, null)<br/>    permission_arns         = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])<br/>    retention_in_days       = optional(number, 7)<br/>    schedule                = string<br/>  }))</pre> | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Indicates if the task should be assigned a public IP | `bool` | `false` | no |
| <a name="input_cloudwatch_event_role_name"></a> [cloudwatch\_event\_role\_name](#input\_cloudwatch\_event\_role\_name) | The name of the role to use for the cloudwatch event rule | `string` | `"nuke-cloudwatch"` | no |
| <a name="input_configuration_secret_name_prefix"></a> [configuration\_secret\_name\_prefix](#input\_configuration\_secret\_name\_prefix) | The prefix to use for AWS Secrets Manager secrets to store the nuke configuration | `string` | `"/lza/configuration/nuke"` | no |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | The amount of CPU to allocate to the container | `number` | `256` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The image to use for the container | `string` | `"ghcr.io/ekristen/aws-nuke"` | no |
| <a name="input_container_image_tag"></a> [container\_image\_tag](#input\_container\_image\_tag) | The tag to use for the container image | `string` | `"v3.26.0-2-g672408a-amd64"` | no |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | The amount of memory to allocate to the container | `number` | `512` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Indicates if a KMS key should be created for the log group | `bool` | `false` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | The name of the ECS cluster we provision run the nuke tasks within | `string` | `"nuke"` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Indicates if container insights should be enabled for the cluster | `bool` | `false` | no |
| <a name="input_iam_execution_role_prefix"></a> [iam\_execution\_role\_prefix](#input\_iam\_execution\_role\_prefix) | The prefix to use for the IAM execution roles used by the tasks | `string` | `"lza-nuke-execution-"` | no |
| <a name="input_iam_task_role_prefix"></a> [iam\_task\_role\_prefix](#input\_iam\_task\_role\_prefix) | The prefix to use for the IAM tasg roles used by the tasks | `string` | `"lza-nuke-"` | no |
| <a name="input_kms_administrator_role_name"></a> [kms\_administrator\_role\_name](#input\_kms\_administrator\_role\_name) | The name of the role to use as the administrator for the KMS key (defaults to account root) | `string` | `null` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | The alias to use for the nuke KMS key | `string` | `"nuke"` | no |
| <a name="input_log_group_kms_key_id"></a> [log\_group\_kms\_key\_id](#input\_log\_group\_kms\_key\_id) | The KMS key id to use for encrypting the log group | `string` | `null` | no |
| <a name="input_log_group_name_prefix"></a> [log\_group\_name\_prefix](#input\_log\_group\_name\_prefix) | The name of the log group to create | `string` | `"/lza/services/nuke"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The KMS key ARN used for the nuke service, if created |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The KMS key ID used for the nuke service, if created |
<!-- END_TF_DOCS -->
