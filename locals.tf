
locals {
  ## The local account id
  account_id = data.aws_caller_identity.current.account_id
  ## The region the resources are being provisioned in
  region = data.aws_region.current.name
  ## Is the unique identifier for resources created by this module 
  name = var.name
  ## Is the key administrator role or principal for any KMS key provisioned
  kms_key_administrator_arn = var.kms_administrator_role_name != null ? "arn:aws:iam::${local.account_id}:role/${var.kms_administrator_role_name}" : "arn:aws:iam::${local.account_id}:root"
  ## Name of the cloudwatch log group to create 
  log_group_name = var.log_group_name == null ? format("/lza/services/%s", local.name) : var.log_group_name
  ## The configuration values passed to the rendered template 
  configuration_data = {
    account_id = local.account_id
    region     = local.region
  }
  ## Is the name of the secret to store the configuration in 
  secret_name = var.configuration_secret_name == null ? format("/lza/configuration/%s", local.name) : var.configuration_secret_name
  ## Is the templated configuration for aws-nuke 
  configuration = templatefile(var.nuke_configuration, local.configuration_data)
}

