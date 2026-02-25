
locals {
  ## The local account id
  account_id = var.account_id
  ## The region the resources are being provisioned in
  region = var.region

  ## Is the key administrator role or principal for any KMS key provisioned
  kms_key_administrator_arn = var.kms_administrator_role_name != null ? "arn:aws:iam::${local.account_id}:role/${var.kms_administrator_role_name}" : "arn:aws:iam::${local.account_id}:root"

  ## The configuration values passed to the rendered template 
  configuration_data = {
    account_id = local.account_id
    region     = local.region
  }

  ## Collection of secret arns for the tasks
  secret_arns = { for k, v in aws_secretsmanager_secret.configuration : k => v.arn }
  ## Collection of secret version arns for the tasks
  secret_version_arns = { for k, v in aws_secretsmanager_secret_version.configuration : k => v.arn }
}

