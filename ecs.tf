
## Provision the ECS Cluster used to run the task 
# tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "current" {
  name = local.name
  tags = var.tags

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

## Provision the task definition for the nuke (aws-nuke) to remove all the resources, 
## Also, we mount the secret from secrets manager to the task 
resource "aws_ecs_task_definition" "task" {
  cpu                      = 256
  execution_role_arn       = aws_iam_role.execution.arn
  family                   = local.name
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  tags                     = var.tags
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = local.name
      image     = format("%s:%s", var.container_image, var.container_image_tag)
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true
    },
  ])
}

