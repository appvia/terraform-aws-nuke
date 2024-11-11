
## Configure a event bridge rule to trigger a lambda function when an ECS task stops
resource "aws_cloudwatch_event_rule" "ecs_task_stopped_rule" {
  for_each = local.tasks_with_notifications

  name_prefix   = "lza-ecs-task-stopped-${lower(each.key)}-"
  description   = "Trigger Lambda when an ECS task in the specified cluster stops."
  force_destroy = true
  tags          = var.tags

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail-type" : ["ECS Task State Change"],
    "detail" : {
      "clusterArn" : [aws_ecs_cluster.current.arn],
      "lastStatus" : ["STOPPED"],
      "taskDefinitionArn" : [{
        "prefix" : each.key
      }]
    }
  })
}

## Configure the lambda function to be triggered by the event bridge rule 
module "lambda_function" {
  for_each = local.tasks_with_notifications
  source   = "terraform-aws-modules/lambda/aws"
  version  = "7.14.0"

  create_package = true
  description    = "Send notifications on the intention to delete resources"
  function_name  = format("lza-nuke-notifications-%s", lower(each.key))
  handler        = "lambda_function.lambda_handler"
  memory_size    = "128"
  runtime        = "python3.9"
  source_path    = format("%s/assets/functions/notification.py", path.module)
  tags           = var.tags
  timeout        = 10

  policy_jsons = [
    jsonencode({
      "Sid" : "AllowPublishToSNS",
      "Effect" : "Allow",
      "Action" : "sns:Publish",
      "Resource" : each.value.sns_topic_arn
    }),
    jsonencode({
      "Sid" : "AllowDescribeLogGroups",
      "Effect" : "Allow",
      "Action" : "logs:DescribeLogGroups",
      "Resource" : "*"
    }),
    jsonencode({
      "Sid" : "AllowQueryLogGroups",
      "Effect" : "Allow",
      "Action" : "logs:FilterLogEvents",
      "Resource" : aws_cloudwatch_log_group.tasks[each.key].arn
    }),
  ]

  ## We are using the log group created above to ensure we control the 
  ## configuration and the retention period of the logs
  logging_log_group                 = format("/aws/lambda/%s", format("lza-nuke-notification-%s", lower(each.key)))
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_retention_in_days = 5
  cloudwatch_logs_skip_destroy      = false

  ## Envionment variables for the Lambda function
  environment_variables = {
    "LOG_GROUP_ARN" = aws_cloudwatch_log_group.tasks[each.key].arn
    "SNS_TOPIC_ARN" = each.value.sns_topic_arn
  }
}

## Allow the event bridge rule to trigger the lambda function 
resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = local.tasks_with_notifications

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function[each.key].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_stopped_rule[each.key].arn
}

## Configure the event target to invoke the lambda function
resource "aws_cloudwatch_event_target" "invoke_lambda" {
  for_each = local.tasks_with_notifications

  rule = aws_cloudwatch_event_rule.ecs_task_stopped_rule[each.key].name
  arn  = module.lambda_function[each.key].lambda_function_arn
}
