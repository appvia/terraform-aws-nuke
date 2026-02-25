
variable "account_id" {
  description = "The account id to use for the resources"
  type        = string
}

variable "region" {
  description = "The region to use for the resources"
  type        = string
}

variable "name" {
  description = "The name of the instance (used to prefix the resources)"
  type        = string
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
    # The permission boundary to use for the task role
    permission_boundary_arn = optional(string, null)
    # The permission ARNs to attach to the task role
    permission_arns = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])
    # The retention in days for the log group
    retention_in_days = optional(number, 7)
    # The schedule to run the task
    schedule = string
  }))
}

variable "secret_arns" {
  description = "A map of task name to the ARN of the SecretsManager secret holding the nuke configuration"
  type        = map(string)
}

variable "container_image" {
  description = "The Lambda-compatible container image URI to use for the nuke function"
  type        = string
}

variable "container_image_tag" {
  description = "The tag to use for the container image"
  type        = string
}

variable "lambda" {
  description = "Lambda function configuration"
  type = object({
    # The architecture to use for the Lambda function (x86_64 or arm64)
    architecture = string
    # The memory size to use for the Lambda function (in MB)
    memory_size = optional(number, 256)
    # The timeout to use for the Lambda function (in seconds, max 900)
    timeout = optional(number, 900)
  })
}

variable "log_group_name_prefix" {
  description = "The prefix to use for CloudWatch log group names"
  type        = string
  default     = "/lza/services/nuke"
}

variable "cloudwatch" {
  description = "CloudWatch log group configuration for the Lambda function"
  type = object({
    # The KMS key id to use for encrypting the log group
    kms_key_id = optional(string, null)
    # The retention period for the log group (in days)
    retention_in_days = optional(number, 7)
    # The class of the log group
    log_group_class = optional(string, "STANDARD")
  })
  default = {
    kms_key_id        = null
    retention_in_days = 7
    log_group_class   = "STANDARD"
  }
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
