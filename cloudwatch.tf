
## Provision a events IAM role, this is used within the cloudwatch trigger, 
## permitting the event to trigger the ECS task

## Provision the ECS events IAM role, which is used to trigger the ECS task
resource "aws_iam_role" "cloudwatch" {
  name = format("events-%s", local.name)
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
resource "aws_cloudwatch_log_group" "current" {
  kms_key_id        = var.log_group_kms_key_id
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

## Provision the cloudwatch event rule to trigger the task 
resource "aws_cloudwatch_event_rule" "current" {
  name                = local.name
  description         = "Used to trigger the nuke task"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

## Provision the cloudwatch event target to run the task 
resource "aws_cloudwatch_event_target" "current" {
  arn       = aws_ecs_cluster.current.arn
  role_arn  = aws_iam_role.cloudwatch.arn
  rule      = aws_cloudwatch_event_rule.current.name
  target_id = local.name

  ecs_target {
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    propagate_tags      = "TASK_DEFINITION"
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.task.arn
    tags                = var.tags

    network_configuration {
      assign_public_ip = var.assign_public_ip
      subnets          = var.subnet_ids
    }
  }
}
