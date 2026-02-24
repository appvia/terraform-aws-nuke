## Create the IAM policy document for the Lambda function
data "aws_iam_policy_document" "permissions" {
  statement {
    sid    = "AllowAllActions"
    effect = "Allow"
    actions = [
      "*",
    ]
    resources = ["*"]
  }
}

## Lambda function that used to handle the aws config rule
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.2.0"

  architectures = [var.lambda_architecture]
  function_name = var.lambda_name
  function_tags = var.tags
  description   = var.lambda_description
  memory_size   = var.lambda_memory_size
  tags          = merge(var.tags, { "Name" = var.lambda_name })
  timeout       = var.lambda_timeout
  image_uri     = format("%s:%s", var.container_image, var.container_image_tag)

  ## Environment variables for the Lambda function
  environment_variables = {


  }

  ## Lambda Role
  create_role                   = true
  role_name                     = var.lambda_name
  role_tags                     = var.tags
  role_force_detach_policies    = true
  role_permissions_boundary     = null
  role_maximum_session_duration = 3600
  role_path                     = "/"

  ## IAM Policy
  attach_policy_json            = true
  attach_network_policy         = false
  attach_cloudwatch_logs_policy = true
  attach_tracing_policy         = true
  policy_json                   = data.aws_iam_policy_document.permissions.json

  ## Cloudwatch Logs
  cloudwatch_logs_tags              = var.tags
  cloudwatch_logs_kms_key_id        = var.cloudwatch.kms_key_id
  cloudwatch_logs_retention_in_days = var.cloudwatch.retention_in_days
  cloudwatch_logs_log_group_class   = var.cloudwatch.log_group_class
}

## Provision a permission to allow aws config to invoke the lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_function.lambda_function_name
  principal      = "events.amazonaws.com"
  statement_id   = "AllowExecutionFromEventBridge"
  source_account = local.account_id
}

## Provision the event bridge rule to trigger the lambda function
resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = var.lambda_name
  description         = var.lambda_description
  schedule_expression = "rate(1 minute)"
  tags                = var.tags
}
