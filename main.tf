
## Provision the network is required 
module "vpc" {
  count   = local.enable_vpc_creation ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.1"

  availability_zones                     = var.network.availability_zones
  enable_default_route_table_association = var.network.enable_default_route_table_association
  enable_default_route_table_propagation = var.network.enable_default_route_table_propagation
  enable_ipam                            = var.network.ipam_pool_id != null ? true : false
  enable_transit_gateway                 = true
  ipam_pool_id                           = var.network.ipam_pool_id
  name                                   = var.network.name
  private_subnet_netmask                 = var.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = var.network.transit_gateway_id
  vpc_cidr                               = var.network.vpc_cidr
  vpc_netmask                            = var.network.vpc_netmask
}

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

## Place the configuration within the parameter store for the ecs task to access 
resource "aws_ssm_parameter" "configuration" {
  description = format("Contains the configuration yaml for the aws-nuke task for %s", local.name)
  name        = format("/lza/parameters/%s", local.name)
  tags        = var.tags
  type        = "String"
  value       = local.configuration
}
