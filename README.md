![Github Actions](../../actions/workflows/terraform.yml/badge.svg)

# Terraform Nuke Module

## Description

The purpose of this module is to provide a method of automated cleanup of resources, using the [aws-nuke](https://ekristen.github.io/aws-nuke/) tool. This module will create a scheduled task that will run an ECS task on a regular basis to clean up resources that are no longer needed.

It is intended to be used in a non-production environment, such as a development or testing account, to ensure that resources are not left running and incurring costs when they are no longer needed.

## Usage

The following provides an example of how to use this module:

```hcl
module "nuke" {
  source = "github.com/appvia/terraform-aws-nuke?ref=main"

  ## Indicates if we should create a KMS key for the log group
  create_kms_key = false
  ## Indicates if the schedule is enabled
  enabled        = true
  ## This is the location of the aws-nuke configuration file, this is
  ## copied into the container via a parameter store value
  nuke_configuration = file("${path.module}/assets/nuke-config.yml.example")
  ## This will create a task that runs every day at midnight
  schedule_expression = "cron(0 0 * * ? *)"
  ## The tags to apply to resources created by this module
  tags = {
    "Environment" = "Testing"
    "GitRepo"     = "https://github.com/appvia/terraform-aws-nuke"
    "Owner"       = "Testing"
    "Product"     = "Terraform AWS Nuke"
  }
  ## This will create an VPC called 'nuke' with 2 availability zones
  ## and a private netmask of 28
  network = {
    name               = "nuke"
    availability_zones = 2
    private_netmask    = 28
    vpc_cidr           = "172.16.0.0/25"
  }
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-aws-modules/kms/aws | 3.1.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | appvia/network/aws | 0.3.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ssm_parameter.configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_nuke_configuration"></a> [nuke\_configuration](#input\_nuke\_configuration) | The YAML configuration to use for aws-nuke | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources created by this module | `map(string)` | n/a | yes |
| <a name="input_container_cpu"></a> [container\_cpu](#input\_container\_cpu) | The amount of CPU to allocate to the container | `number` | `256` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The image to use for the container | `string` | `"ghcr.io/ekristen/aws-nuke"` | no |
| <a name="input_container_image_tag"></a> [container\_image\_tag](#input\_container\_image\_tag) | The tag to use for the container image | `string` | `"v3.26.0-2-g672408a-amd64"` | no |
| <a name="input_container_memory"></a> [container\_memory](#input\_container\_memory) | The amount of memory to allocate to the container | `number` | `512` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Indicates if a KMS key should be created for the log group | `bool` | `false` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Indicates if container insights should be enabled for the cluster | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Indicates the scheduled task should be enabled, else we cofingure the task to be disabled | `bool` | `true` | no |
| <a name="input_existing_vpc"></a> [existing\_vpc](#input\_existing\_vpc) | When reusing an existing network, these are details of the network to use | <pre>object({<br/>    vpc_id = string<br/>    # The security group id to use when not creating a new network <br/>    security_group_id = optional(string, "")<br/>    # The subnet mask for private subnets, when creating the network i.e subnet-id => 10.90.0.0/24<br/>    private_subnet_ids = optional(list(string), [])<br/>    # The ids of the private subnets to use when not creating a new network <br/>  })</pre> | `null` | no |
| <a name="input_kms_administrator_role_name"></a> [kms\_administrator\_role\_name](#input\_kms\_administrator\_role\_name) | The name of the role to use as the administrator for the KMS key (defaults to account root) | `string` | `null` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | The alias to use for the nuke KMS key | `string` | `"nuke"` | no |
| <a name="input_log_group_kms_key_id"></a> [log\_group\_kms\_key\_id](#input\_log\_group\_kms\_key\_id) | The KMS key id to use for encrypting the log group | `string` | `null` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | The name of the log group to create | `string` | `"nuke"` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | The number of days to retain logs for | `number` | `7` | no |
| <a name="input_network"></a> [network](#input\_network) | The network to use for the endpoints and optinal resolvers | <pre>object({<br/>    availability_zones = optional(number, 2)<br/>    # The id of the ipam pool to use when creating the network<br/>    name = optional(string, "nuke")<br/>    # The name of the network to create<br/>    private_netmask = optional(number, 28)<br/>    ## The transit gateway id to use for the network<br/>    vpc_cidr = optional(string, "")<br/>    # The vpc id to use when reusing an existing network <br/>  })</pre> | `null` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | The schedule expression to use for the event rule | `string` | `"cron(0 0 * * ? *)"` | no |
| <a name="input_task_role_additional_policies"></a> [task\_role\_additional\_policies](#input\_task\_role\_additional\_policies) | A map of inline policies to attach to the IAM role | <pre>map(object({<br/>    policy = string<br/>  }))</pre> | `null` | no |
| <a name="input_task_role_permissions_arns"></a> [task\_role\_permissions\_arns](#input\_task\_role\_permissions\_arns) | A list of permissions to attach to the IAM role | `list(string)` | <pre>[<br/>  "arn:aws:iam::aws:policy/AdministratorAccess"<br/>]</pre> | no |
| <a name="input_task_role_permissions_boundary_arn"></a> [task\_role\_permissions\_boundary\_arn](#input\_task\_role\_permissions\_boundary\_arn) | The boundary policy to attach to the IAM role | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_parameter_store_arn"></a> [parameter\_store\_arn](#output\_parameter\_store\_arn) | The ARN of the parameter store containing the nuke configuration |
| <a name="output_private_subnet_id_by_az"></a> [private\_subnet\_id\_by\_az](#output\_private\_subnet\_id\_by\_az) | The private subnets to use for the nuke service |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The VPC where the nuke service is running |
<!-- END_TF_DOCS -->
