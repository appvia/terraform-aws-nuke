
locals {
  ## The local account id
  account_id = var.account_id
  ## The region the resources are being provisioned in
  region = var.region

  ## A map of tasks with notifications enabled
  tasks_with_notifications = { for k, v in var.tasks : k => v if try(v.notifications.sns_topic_arn, null) != null }

  ## Collect all unique managed policy ARNs from all tasks to attach to the Lambda role
  all_permission_arns = toset(flatten([for k, v in var.tasks : v.permission_arns]))

  ## Flatten all additional_permissions from all tasks for inline policy attachment
  task_additional_permissions_all = flatten([
    for task_name, task_config in var.tasks : [
      for permission_name, permission_config in task_config.additional_permissions : {
        key    = format("%s-%s", task_name, permission_name)
        policy = permission_config.policy
      }
    ]
  ])

  ## Map of all additional permissions keyed for for_each
  task_additional_permissions = {
    for p in local.task_additional_permissions_all : p.key => p.policy
  }
}
