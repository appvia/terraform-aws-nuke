## Provision the IAM role for the ECS task: these are the permissions granted to the 
## task to operate under
resource "aws_iam_role" "task" {
  description          = "Used by the ECS task to perform actions and remove resources, as part of the nuke service"
  name                 = local.name
  permissions_boundary = var.task_role_permissions_boundary_arn
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

## Provision the ECS execution IAM role; this is used by the task to execute within 
## the ECS cluster
resource "aws_iam_role" "execution" {
  description = "Used by the ECS task to execute within the ECS cluster by the nuke service"
  name        = format("execution-%s", local.name)
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

## Allow any additional permissions to be attached to the task role - these are inline 
## policies applied to the task
resource "aws_iam_role_policy" "task_permissions" {
  for_each = var.task_role_additional_policies

  role   = aws_iam_role.task.name
  name   = each.key
  policy = each.value.policy
}

## Attach any managed polices to the task role - i.e the permissions which the task can 
## perform within the AWS account/s
resource "aws_iam_role_policy_attachment" "task_permissions" {
  for_each = toset(var.task_role_permissions_arns)

  role       = aws_iam_role.task.name
  policy_arn = each.value
}

#
## Permissions for the ECS Execution role 
#

## Attach the Amazon ECS task execution role policy to the execution role
resource "aws_iam_role_policy_attachment" "execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.execution.name
}


## Allow the ECS task to retrieve the secret from the secrets manager 
resource "aws_iam_role_policy" "execution_secrets" {
  name = "allow-sm-configuration"
  role = aws_iam_role.execution.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSecretsManager",
        Action = ["secretsmanager:GetSecretValue"],
        Effect = "Allow",
        Resource = [
          aws_secretsmanager_secret.configuration.arn
        ]
      }
    ]
  })
}

