
## Provision a events IAM role, this is used within the cloudwatch trigger, 
## permitting the event to trigger the ECS task

## Provision the ECS events IAM role, which is used to trigger the ECS task
resource "aws_iam_role" "cloudwatch" {
  name = var.cloudwatch_event_role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

## Attach the ECS events policy to the role 
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
  role       = aws_iam_role.cloudwatch.name
}

## Provision a CloudWatch Log Group for the task to use 
# trivy:ignore:AVD-AWS-0017
resource "aws_cloudwatch_log_group" "tasks" {
  for_each = var.tasks

  kms_key_id        = var.log_group_kms_key_id
  name              = format("%s/%s", var.log_group_name_prefix, each.key)
  retention_in_days = each.value.retention_in_days
  tags              = var.tags
}

## Provision the cloudwatch event rule to trigger the task - we need to provision  
## an event rule per task 
resource "aws_cloudwatch_event_rule" "tasks" {
  for_each = var.tasks

  name                = format("%s-%s", var.cloudwatch_event_rule_prefix, each.key)
  description         = each.value.description
  schedule_expression = each.value.schedule
  tags                = var.tags
}

## Provision the cloudwatch event target to run the task 
resource "aws_cloudwatch_event_target" "tasks" {
  for_each = var.tasks

  arn       = aws_ecs_cluster.current.arn
  role_arn  = aws_iam_role.cloudwatch.arn
  rule      = aws_cloudwatch_event_rule.tasks[each.key].name
  target_id = format("nuke-%s", each.key)

  ecs_target {
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    propagate_tags      = "TASK_DEFINITION"
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.tasks[each.key].arn
    tags                = var.tags

    network_configuration {
      assign_public_ip = var.assign_public_ip
      subnets          = var.subnet_ids
    }
  }
}
