
locals {
  ## The local account id
  account_id = data.aws_caller_identity.current.account_id

  ## Indicates if we are creating the vpc or reusing an existing one
  enable_vpc_creation = var.network == null ? true : false

  ## The region the resources are being provisioned in
  region = data.aws_region.current.name

  ## Is the unique identifier for resources created by this module 
  name = format("nuke-%s", local.region)

  ## Is the key administrator role or principal for any KMS key provisioned
  kms_key_administrator_arn = var.kms_administrator_role_name != null ? "arn:aws:iam::${local.account_id}:role/${var.kms_administrator_role_name}" : "arn:aws:iam::${local.account_id}:root"

  ## The VPC ID for the inspection service, either created or provided
  vpc_id = local.enable_vpc_creation ? module.vpc[0].vpc_id : try(var.existing_vpc.vpc_id, null)

  ## The private subnets to use for the ecs service 
  private_subnet_id_by_az = local.enable_vpc_creation ? module.vpc[0].private_subnet_id_by_az : try(var.existing_vpc.private_subnet_ids, null)

  ## The security group to use for the ecs service 
  security_group_id = local.enable_vpc_creation ? module.vpc[0].security_group_id : try(var.existing_vpc.security_group_id, null)

  ## The configuration values passed to the rendered template 
  configuration_data = {
    account_id = local.account_id
    region     = local.region
  }

  ## Is the templated configuration for aws-nuke 
  configuration = templatefile(var.nuke_configuration, local.configuration_data)
}

