
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

  ## A map of tasks with notifications enabled 
  tasks_with_notifications = { for k, v in var.tasks : k => v if try(v.notifications.sns_topic_arn, null) != null }

  ## We need to create a map of task->permission_arn for every task 
  task_permissions_all = flatten([
    for k, v in var.tasks : [
      for arn in v.permission_arns : {
        permission_arn = arn
        task           = k
      }
    ]
  ])
  ## We need to create a map of task->additional_permissions for every task 
  task_permissions_arns = {
    for k, v in local.task_permissions_all : format("%s-%s", v.task, v.permission_arn) => {
      task           = v.task
      permission_arn = v.permission_arn
    }
  }

  ## We need to create a map of task->additional_permissions for every task 
  task_additional_permissions_all = flatten([
    for task_name, task_config in var.tasks : [
      for permission_name, permission_config in task_config.additional_permissions : {
        permission_name = permission_name
        policy          = permission_config.policy
        task            = task_name
      }
    ]
  ])

  ## We need to create a map of task->additional_permissions for every task
  task_additional_permissions = {
    for task, config in local.task_additional_permissions_all : format("%s-%s", config.task, config.permission_name) => {
      permission_name = config.permission_name
      policy          = config.policy
      task            = config.task
    }
  }
}

