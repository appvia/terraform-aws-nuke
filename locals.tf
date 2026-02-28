
locals {
  ## ARN for the account root
  account_root_arn = "arn:aws:iam::${var.account_id}:root"
  ## The region the resources are being provisioned in
  region = var.region
  ## ARN for the KMS key administrator role
  kms_key_administrator_role_arn = "arn:aws:iam::${var.account_id}:role/${var.kms_administrator_role_name}"
  ## Is the key administrator role or principal for any KMS key provisioned
  kms_key_administrator_arn = var.kms_administrator_role_name != "" ? local.kms_key_administrator_role_arn : local.account_root_arn
  ## The configuration values passed to the rendered template
  configuration_data = {
    # The account id
    account_id = var.account_id
    # The region
    region = local.region
  }
  ## Collection of secret arns for the tasks
  secret_arns = { for k, v in aws_secretsmanager_secret.configuration : k => v.arn }
}

