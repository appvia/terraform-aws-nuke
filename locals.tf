
locals {
  ## The local account id
  account_id = var.account_id
  ## The region the resources are being provisioned in
  region = var.region
  ## Is the unique identifier for resources created by this module 
  name = var.name

  ## Is the key administrator role or principal for any KMS key provisioned
  kms_key_administrator_arn = var.kms_administrator_role_name != null ? "arn:aws:iam::${local.account_id}:role/${var.kms_administrator_role_name}" : "arn:aws:iam::${local.account_id}:root"

  ## The configuration values passed to the rendered template 
  configuration_data = {
    account_id = local.account_id
    region     = local.region
  }

  ## We need to create a map of task->permission_arn for every task 
  task_permissions_flattened = flatten([
    for task, config in var.tasks : [
      for permission_arn in config.permission_arns : {
        permission_arn = permission_arn
        task           = task
      }
    ]
  ])
  ## We need to create a map of task->additional_permissions for every task 
  task_permissions_arns = {
    for task, config in local.task_permissions_flattened : format("%s-%s", config.task, config.permission_arn) => {
      task           = config.task
      permission_arn = config.permission_arn
    }
  }

  ## We need to create a map of task->additional_permissions for every task 
  task_additional_permissions_flattened = flatten([
    for task, config in var.tasks : [
      for permission_arn, permission in config.additional_permissions : {
        task   = task
        policy = permission.policy
      }
    ]
  ])

  ## We need to create a map of task->additional_permissions for every task
  task_additional_permissions = {
    for task, config in local.task_additional_permissions_flattened : format("%s-%s", config.task, task) => {
      task   = config.task
      policy = config.policy
    }
  }
}

