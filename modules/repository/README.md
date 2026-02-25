# Repository Sub-module

## Introduction

This sub-module provisions a private **ECR repository** to host the Lambda-compatible [aws-nuke](https://ekristen.github.io/aws-nuke/) wrapper image. It is intended to be used alongside the Lambda compute backend (`modules/lambda`) when running aws-nuke in Lambda mode.

Use this module to create the ECR repository once (typically in a shared tooling account), then build and push the wrapper image from [`assets/docker/`](../../assets/docker/) via CI/CD or manually.

## Features

- **Private ECR repository** -- provisions an ECR repository with immutable tags (with configurable exclusion filters for `latest*` and custom patterns).
- **Cross-account pull access** -- grant pull access by specific account IDs (`account_ids`) or by AWS Organization ID (`organization_id`) for org-wide access.
- **Image scanning** -- scan-on-push enabled by default for vulnerability detection.
- **KMS encryption** -- optional KMS key for repository encryption (falls back to AES256).
- **Immutable tag exclusions** -- configurable exclusion filters allow mutable tags where needed (e.g. `latest`).

## Usage

```hcl
module "nuke_ecr" {
  source = "github.com/appvia/terraform-aws-nuke//modules/repository?ref=main"

  repository_name = "lz/operations/aws-nuke"
  account_ids     = ["123456789012", "234567890123"]
  tags            = local.tags
}
```

To grant pull access to an entire AWS Organization instead of individual accounts:

```hcl
module "nuke_ecr" {
  source = "github.com/appvia/terraform-aws-nuke//modules/repository?ref=main"

  repository_name = "lz/operations/aws-nuke"
  organization_id = "o-1234567890"
  tags            = local.tags
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
| <a name="input_account_ids"></a> [account\_ids](#input\_account\_ids) | The account ids to allow access to the repository | `list(string)` | `[]` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | AWS Organization ID used to pull the nuke container image from the AWS ECR Public Gallery | `string` | `null` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | The name of the repository to use for the nuke container | `string` | `"lz/operations/aws-nuke"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_repository_arn"></a> [repository\_arn](#output\_repository\_arn) | The ARN of the ECR repository for the nuke container |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | The name of the ECR repository for the nuke container |
<!-- END_TF_DOCS -->