## Craft a policy document allowing the ECS task to assume the role, and execute within 
## the ECS cluster
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_configuration" {
  ## Allow the ECS task to retrieve the parameters from the parameter store 
  statement {
    sid    = "AllowSSMConfiguration"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [aws_ssm_parameter.configuration.arn]
  }
}

## Provision the IAM role for the ECS task: these are the permissions granted to the 
## task to operate under
resource "aws_iam_role" "task" {
  assume_role_policy   = jsonencode(data.aws_iam_policy_document.ecs_assume)
  description          = "Used by the ECS task to perform actions and remove resources, as part of the nuke service"
  name                 = local.name
  permissions_boundary = var.task_role_permissions_boundary_arn
  tags                 = var.tags
}

## Allow the task access to the parameter store, to retrieve the configuration
resource "aws_iam_role_policy" "task_configuration" {
  name   = "allow-ssm-configuration"
  role   = aws_iam_role.task.name
  policy = data.aws_iam_policy_document.task_configuration.json
}

## Allow any additional permissions to be attached to the task role - these are inline 
## policies applied to the task
resource "aws_iam_role_policy" "task_permissions" {
  for_each = var.task_role_additional_policies != null ? var.task_role_additional_policies : {}

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


## Provision the ECS execution IAM role; this is used by the task to execute within 
## the ECS cluster
resource "aws_iam_role" "execution" {
  assume_role_policy = jsonencode(data.aws_iam_policy_document.ecs_assume)
  name               = format("execution-%s", local.name)
  tags               = var.tags
}

## Assign the IAM permissions to the execution role, allowing the operate within the ECS cluster 
resource "aws_iam_role_policy_attachment" "execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.execution.name
}

