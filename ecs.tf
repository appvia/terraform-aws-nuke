
## Provision the ECS Cluster used to run the task
# tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "current" {
  name = var.ecs_cluster_name
  tags = var.tags

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

## Provision the ECS execution IAM role; this is used by the task to execute within
## the ECS cluster
resource "aws_iam_role" "execution" {
  for_each = var.tasks

  description = format("Used by the ECS task to execute within the ECS cluster by the nuke service: '%s'", each.key)
  name_prefix = format("%s%s", var.iam_execution_role_prefix, each.key)
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

## Provision a role for the task to use, this is used to perform actions and remove
resource "aws_iam_role" "task" {
  for_each = var.tasks

  description          = format("Permissions for the ECS nuke task: '%s' to run under", each.key)
  name_prefix          = format("%s%s", var.iam_task_role_prefix, each.key)
  permissions_boundary = each.value.permission_boundary_arn
  tags                 = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

## Attach any managed polices to the task role - i.e the permissions which the task can
## perform within the AWS account/s
resource "aws_iam_role_policy_attachment" "task_permissions_arns" {
  for_each = local.task_permissions_arns

  role       = aws_iam_role.task[each.value.task].name
  policy_arn = each.value.permission_arn
}

## Allow any additional permissions to be attached to the task role - these are inline
## policies applied to the task
resource "aws_iam_role_policy" "task_additional_permissions" {
  for_each = local.task_additional_permissions

  role   = aws_iam_role.task[each.value.task].name
  name   = each.value.permission_name
  policy = each.value.policy
}

## Attach the Amazon ECS task execution role policy to the execution role
resource "aws_iam_role_policy_attachment" "execution" {
  for_each = var.tasks

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.execution[each.key].name
}

## Allow the ECS task access to the ECR repository to pull the image
resource "aws_iam_role_policy" "execution_ecr" {
  for_each = var.tasks

  name = "allow-ecr-pull"
  role = aws_iam_role.execution[each.key].name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowECRPull",
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

## Allow the ECS task to retrieve the secret from the secrets manager
resource "aws_iam_role_policy" "execution_secrets" {
  for_each = var.tasks

  name = "allow-secretmanager-readonly"
  role = aws_iam_role.execution[each.key].name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSecretsManager",
        Action = ["secretsmanager:GetSecretValue"],
        Effect = "Allow",
        Resource = [
          aws_secretsmanager_secret.configuration[each.key].arn,
        ]
      }
    ]
  })
}

## Provision the task definition for the nuke (aws-nuke) to remove all the resources,
## Also, we mount the secret from secrets manager to the task
resource "aws_ecs_task_definition" "tasks" {
  for_each = var.tasks

  cpu                      = var.container_cpu
  execution_role_arn       = aws_iam_role.execution[each.key].arn
  family                   = format("nuke-%s", each.key)
  memory                   = var.container_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  tags                     = merge(var.tags, { "Name" = each.key })
  task_role_arn            = aws_iam_role.task[each.key].arn

  container_definitions = jsonencode([
    {
      name                   = format("nuke-%s", each.key)
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
          each.value.dry_run ? "" : "--no-dry-run",
        ]),
        "echo '[AWS-NUKE] TASK COMPLETE'",
      ])]

      secrets = [
        {
          name      = "NUKE_CONFIG"
          valueFrom = aws_secretsmanager_secret_version.configuration[each.key].arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.tasks[each.key].name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
