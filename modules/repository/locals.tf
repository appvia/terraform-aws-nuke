
locals {
  ## The region the resources are being provisioned in
  region = data.aws_region.current.region
  ## The local account id
  account_id = data.aws_caller_identity.current.account_id
  ## Expected ARN for the AWS ECR repository
  repository_arn = "arn:aws:ecr:${local.region}:${local.account_id}:repository/${var.repository_name}"
}
