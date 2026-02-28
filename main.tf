## Provision a KMS for the log group to use, if required
module "kms" {
  count   = var.create_kms_key ? 1 : 0
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = [var.name]
  deletion_window_in_days = 7
  description             = "Used to encrypt the log group for the nuke task"
  enable_key_rotation     = true
  is_enabled              = true
  key_administrators      = [local.kms_key_administrator_arn]
  key_owners              = [local.kms_key_administrator_arn]
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false
  tags                    = merge(var.tags, { "Name" = var.name })
}

## Place the configuration within the parameter store for the ecs task to access
# trivy:ignore:AVD-AWS-0017
# tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "configuration" {
  for_each = var.tasks

  description             = format("Contains the configuration yaml for the aws-nuke '%s' task", each.key)
  name                    = format("%s/%s", var.configuration_secret_name_prefix, each.key)
  recovery_window_in_days = 0
  tags                    = merge(var.tags, { "Name" = format("%s/%s", var.name, each.key) })
}

## Attach a resource policy to each secret
resource "aws_secretsmanager_secret_policy" "configuration" {
  for_each = var.tasks

  secret_arn = aws_secretsmanager_secret.configuration[each.key].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerRead"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Principal = {
          AWS = [format("arn:aws:iam::%s:root", var.account_id)]
        }
        Resource = "*"
      }
    ]
  })
}

## Provision a secret version for the configuration
resource "aws_secretsmanager_secret_version" "configuration" {
  for_each = var.tasks

  secret_id     = aws_secretsmanager_secret.configuration[each.key].id
  secret_string = templatestring(each.value.configuration, local.configuration_data)
}

## Provision the ECS cluster, if required
module "ecs_nuke" {
  count  = var.ecs != null ? 1 : 0
  source = "./modules/ecs"

  account_id                             = var.account_id
  assign_public_ip                       = var.ecs.assign_public_ip
  cloudwatch_log_group_kms_key_id        = try(module.kms[0].key_id, var.ecs.cloudwatch_log_group_kms_key_id)
  cloudwatch_log_group_prefix            = var.ecs.cloudwatch_log_group_prefix
  cloudwatch_log_group_retention_in_days = var.ecs.cloudwatch_log_group_retention_in_days
  container_cpu                          = var.ecs.container_cpu
  container_image                        = var.container_image
  container_image_tag                    = var.container_image_tag
  container_memory                       = var.ecs.container_memory
  enable_container_insights              = var.ecs.enable_container_insights
  name                                   = var.name
  region                                 = var.region
  secret_arns                            = local.secret_arns
  subnet_ids                             = var.ecs.subnet_ids
  tags                                   = var.tags
  tasks                                  = var.tasks

  depends_on = [
    aws_secretsmanager_secret.configuration,
    aws_secretsmanager_secret_policy.configuration,
    aws_secretsmanager_secret_version.configuration,
    module.kms,
  ]
}

## Provision the Lambda function, if required
module "lambda_nuke" {
  count  = var.lambda != null ? 1 : 0
  source = "./modules/lambda"

  account_id                             = var.account_id
  cloudwatch_log_group_class             = var.lambda.cloudwatch_log_group_class
  cloudwatch_log_group_kms_key_id        = try(module.kms[0].key_id, var.lambda.cloudwatch_log_group_kms_key_id)
  cloudwatch_log_group_retention_in_days = var.lambda.cloudwatch_log_group_retention_in_days
  configuration_secret_name_prefix       = var.configuration_secret_name_prefix
  container_image                        = var.container_image
  lambda_architecture                    = var.lambda.architecture
  lambda_memory_size                     = var.lambda.memory_size
  lambda_timeout                         = var.lambda.timeout
  name                                   = var.name
  region                                 = var.region
  tags                                   = var.tags
  tasks                                  = var.tasks
}
