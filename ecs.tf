
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
  cpu                      = var.container_cpu
  execution_role_arn       = aws_iam_role.execution.arn
  family                   = local.name
  memory                   = var.container_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  tags                     = var.tags
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name                   = local.name
      cpu                    = var.container_cpu
      entryPoint             = ["/bin/sh", "-c"]
      environment            = []
      essential              = true
      image                  = format("%s:%s", var.container_image, var.container_image_tag)
      memory                 = var.container_memory
      mountPoints            = []
      portMappings           = []
      readonlyRootFilesystem = false
      systemControls         = []
      volumesFrom            = []

      command = [join("; ", [
        "echo '[AWS-NUKE] RUNNING TASK'",
        "echo \"$NUKE_CONFIG\" > /tmp/config.yml",
        join(" ", [
          "/usr/local/bin/aws-nuke run",
          "--config /tmp/config.yml",
          "--no-alias-check",
          "--force",
          var.enable_deletion ? "--no-dry-run" : "",
        ]),
        "echo '[AWS-NUKE] TASK COMPLETE'",
      ])]

      secrets = [
        {
          name      = "NUKE_CONFIG"
          valueFrom = aws_secretsmanager_secret_version.configuration.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.current.name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
