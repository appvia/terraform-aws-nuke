## Build an inline IAM policy granting SecretsManager read access for all task configs.
## The Lambda function reads nuke configuration from SecretsManager at invocation time.
data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid       = "AllowSecretsManagerRead"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = values(var.secret_arns)
  }

  statement {
    sid       = "AllowECRPull"
    effect    = "Allow"
    actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = ["*"]
  }
}

## Lambda function that runs aws-nuke via a Lambda-compatible container image.
## A single function handles all tasks; per-task config is injected via EventBridge input.
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.5.0"

  architectures  = [var.lambda_architecture]
  create_package = false
  description    = format("Runs the AWS Nuke within the account, for the %q task", var.name)
  function_name  = var.name
  memory_size    = var.lambda_memory_size
  package_type   = "Image"
  tags           = merge(var.tags, { "Name" = var.name })
  timeout        = var.lambda_timeout
  image_uri      = var.container_image

  ## Lambda Role
  create_role                   = true
  role_name                     = var.name
  role_tags                     = var.tags
  role_force_detach_policies    = true
  role_maximum_session_duration = 3600
  role_path                     = "/"

  ## Attach the SecretsManager read policy as an inline policy
  attach_policy_json            = true
  attach_network_policy         = false
  attach_cloudwatch_logs_policy = true
  attach_tracing_policy         = true
  policy_json                   = data.aws_iam_policy_document.secrets_access.json

  ## Attach combined managed policy ARNs from all tasks (typically AdministratorAccess)
  attach_policies    = length(local.all_permission_arns) > 0
  number_of_policies = length(local.all_permission_arns)
  policies           = tolist(local.all_permission_arns)

  ## CloudWatch Logs
  cloudwatch_logs_tags              = var.tags
  cloudwatch_logs_kms_key_id        = var.cloudwatch_log_group_kms_key_id
  cloudwatch_logs_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_logs_log_group_class   = var.cloudwatch_log_group_class
}

## Attach any additional inline policies from tasks to the Lambda execution role
resource "aws_iam_role_policy" "additional_permissions" {
  for_each = local.task_additional_permissions

  name   = each.key
  role   = module.lambda_function.lambda_role_name
  policy = each.value
}

## Provision the event bridge rule to trigger the Lambda function
resource "aws_cloudwatch_event_rule" "tasks" {
  for_each = var.tasks

  name                = format("%s-%s", var.name, each.key)
  description         = each.value.description
  schedule_expression = each.value.schedule
  tags                = var.tags
}

## Provision one EventBridge target per task, passing task config as static JSON input.
## The Lambda handler receives: task_name, dry_run, secret_arn, and optionally sns_topic_arn.
resource "aws_cloudwatch_event_target" "tasks" {
  for_each = var.tasks

  arn       = module.lambda_function.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.tasks[each.key].name
  target_id = format("%s-%s", var.name, each.key)

  input = jsonencode({
    dry_run       = each.value.dry_run
    secret_arn    = var.secret_arns[each.key]
    sns_topic_arn = try(each.value.notifications.sns_topic_arn, null)
    task_name     = each.key
  })
}

## Allow the EventBridge rule to invoke the Lambda function
resource "aws_lambda_permission" "allow_event_bridge" {
  for_each = var.tasks

  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "events.amazonaws.com"
  statement_id  = format("AllowEventBridge-%s", each.key)
  source_arn    = aws_cloudwatch_event_rule.tasks[each.key].arn
}

## Allow the Lambda to publish SNS notifications for tasks that have notifications configured
resource "aws_iam_role_policy" "sns_publish" {
  count = length(local.tasks_with_notifications) > 0 ? 1 : 0

  name = "allow-sns-publish"
  role = module.lambda_function.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowSNSPublish",
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = distinct([for k, v in local.tasks_with_notifications : v.notifications.sns_topic_arn])
      }
    ]
  })
}
