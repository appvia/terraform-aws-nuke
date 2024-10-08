
## Provision a KMS for the log group to use, if required 
module "kms" {
  count   = var.create_kms_key ? 1 : 0
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases                 = [var.kms_key_alias]
  deletion_window_in_days = 7
  description             = "Used to encrypt the log group for the nuke task"
  enable_key_rotation     = true
  is_enabled              = true
  key_administrators      = [local.kms_key_administrator_arn]
  key_owners              = [local.kms_key_administrator_arn]
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false
  tags                    = merge(var.tags, { "Name" = var.kms_key_alias })
}

## Craft a IAM policy document that permission the ecs task to retrieve 
## the secret from secrets manager 
data "aws_iam_policy_document" "secrets_manager" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", local.account_id)]
    }
    resources = [
      format("arn:aws:secretsmanager:%s:%s:secret:%s", local.region, local.account_id, local.secret_name),
    ]
  }
}

## Place the configuration within the parameter store for the ecs task to access 
# trivy:ignore:AVD-AWS-0017
# tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "configuration" {
  description             = format("Contains the configuration yaml for the aws-nuke task for %s", local.name)
  name                    = local.secret_name
  policy                  = data.aws_iam_policy_document.secrets_manager.json
  recovery_window_in_days = 0
  tags                    = var.tags
}

## Provision a secret version for the configuration
resource "aws_secretsmanager_secret_version" "configuration" {
  secret_id     = aws_secretsmanager_secret.configuration.id
  secret_string = local.configuration
}
