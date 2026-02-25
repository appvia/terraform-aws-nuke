locals {
  ## The actions to allow for the repository policy
  repository_actions = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:BatchGetImage",
    "ecr:DescribeRepositories",
    "ecr:GetAuthorizationToken",
    "ecr:GetDownloadUrlForLayer",
    "ecr:GetRepositoryPolicy",
    "ecr:ListImages",
  ]
}

## Craft a repository IAM policy document for the nuke container
data "aws_iam_policy_document" "nuke_repository" {
  statement {
    sid    = "AllowPullFromRepository"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [for account_id in var.account_ids : format("arn:aws:iam::%s:root", account_id)]
    }
    actions   = local.repository_actions
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.organization_id != null ? [1] : []

    content {
      sid       = "AllowPullFromOrganization"
      effect    = "Allow"
      actions   = local.repository_actions
      resources = [local.repository_arn]

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }
}

## Provision a repository with ECR for the nuke container
resource "aws_ecr_repository" "nuke" {
  name                 = var.repository_name
  tags                 = var.tags
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  encryption_configuration {
    encryption_type = var.kms_key_id != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_id
  }

  image_scanning_configuration {
    scan_on_push = var.enable_scan_on_push
  }

  ## Add the immutable exclusions to the repository
  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }

  ## Add the dynamic immutable exclusions to the repository
  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = var.immutable_exclusions

    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }
}

## Attach the repository IAM policy to the repository
resource "aws_ecr_repository_policy" "nuke" {
  repository = aws_ecr_repository.nuke.name
  policy     = data.aws_iam_policy_document.nuke_repository.json
}