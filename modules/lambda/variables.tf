
variable "account_id" {
  description = "The account id to use for the resources"
  type        = string
}

variable "cloudwatch_log_group_class" {
  description = "The class of the CloudWatch log group"
  type        = string
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The KMS key id to use for encrypting the log group"
  type        = string
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The retention period for the CloudWatch log group"
  type        = number
}

variable "configuration_secret_name_prefix" {
  description = "The prefix used for AWS Secrets Manager task configuration secrets"
  type        = string
}

variable "container_image" {
  description = "Optional Lambda-compatible container image URI to use for the nuke function (IMAGE:TAG)"
  type        = string
  default     = null
}

variable "lambda_architecture" {
  description = "The architecture to use for the Lambda function - must match the platform the container image was built for"
  type        = string
  default     = "arm64"
}

variable "lambda_log_level" {
  description = "The log level to use for the Lambda function"
  type        = string
  default     = "INFO"
}

variable "lambda_memory_size" {
  description = "The memory size to use for the Lambda function"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "The timeout to use for the Lambda function"
  type        = number
  default     = 900
}

variable "name" {
  description = "The name of the instance (used to prefix the resources)"
  type        = string
}

variable "region" {
  description = "The region to use for the resources"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}

variable "tasks" {
  description = "A collection of nuke tasks to run and when to run them"
  type = map(object({
    # Additional permissions to attach to the task role
    additional_permissions = optional(map(object({
      # The policy to attach to the task role
      policy = string
    })), {})
    # The configuration to use for the task
    configuration = string
    # The description to use for the task
    description = string
    # Indicates if the task should be a dry run (default is true)
    dry_run = optional(bool, true)
    # The notifications to send for the task
    notifications = optional(object({
      # The SNS topic to send the notification to
      sns_topic_arn = optional(string, null)
      }), {
      sns_topic_arn = null
    })
    # The permission ARNs to attach to the task role
    permission_arns = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])
    # The permission boundary to use for the task role
    permission_boundary_arn = optional(string, null)
    # The schedule to run the task
    schedule = string
  }))
}
