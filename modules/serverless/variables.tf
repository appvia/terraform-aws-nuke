
variable "account_id" {
  description = "The account id to use for the resources"
  type        = string
}

variable "region" {
  description = "The region to use for the resources"
  type        = string
}

variable "create_kms_key" {
  description = "Indicates if a KMS key should be created for the log group"
  type        = bool
  default     = false
}

variable "cloudwatch_event_role_name_prefix" {
  description = "The name of the role to use for the cloudwatch event rule"
  type        = string
  default     = "nuke-cloudwatch-"
}

variable "cloudwatch_event_rule_prefix" {
  description = "The prefix to use for the cloudwatch event rule"
  type        = string
  default     = "lza-nuke"
}

variable "tasks" {
  description = "A collection of nuke tasks to run and when to run them"
  type = map(object({
    additional_permissions = optional(map(object({
      policy = string
    })), {})
    configuration = string
    description   = string
    dry_run       = optional(bool, true)
    notifications = optional(object({
      sns_topic_arn = optional(string, null)
      }), {
      sns_topic_arn = null
    })
    permission_boundary_arn = optional(string, null)
    permission_arns         = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])
    retention_in_days       = optional(number, 7)
    schedule                = string
  }))

  ## The tast must have a configuration
  validation {
    condition     = alltrue([for task in keys(var.tasks) : contains(keys(var.tasks[task]), "configuration")])
    error_message = "The task must have a configuration"
  }

  ## The task configuration must not be empty
  validation {
    condition     = alltrue([for task in keys(var.tasks) : length(var.tasks[task].configuration) > 0])
    error_message = "The task configuration must not be empty"
  }

  ## The task key must be all lowercase and contain only alpha characters
  validation {
    condition     = alltrue([for task in keys(var.tasks) : can(regex("^[a-z\\_\\-]+$", task))])
    error_message = "The task key must be all lowercase and contain only alphanumeric characters"
  }

  ## The task name cannot be longer than 32
  validation {
    condition     = alltrue([for task in keys(var.tasks) : length(task) <= 32])
    error_message = "The task name cannot be longer than 32 characters"
  }
}

variable "kms_key_alias" {
  description = "The alias to use for the nuke KMS key"
  type        = string
  default     = "nuke"
}

variable "kms_administrator_role_name" {
  description = "The name of the role to use as the administrator for the KMS key (defaults to account root)"
  type        = string
  default     = null
}

variable "lambda_name" {
  description = "The name of the lambda function"
  type        = string
  default     = "lza-nuke"
}

variable "lambda_description" {
  description = "The lambda function description"
  type        = string
  default     = "Lambda function to run the AWS Nuke tasks"
}

variable "lambda_timeout" {
  description = "The amount of time to allow the lambda function to run before timing out (in seconds)"
  type        = number
  default     = 900
}

variable "lambda_architecture" {
  description = "The architectures to support for the lambda function"
  type        = string
  default     = "arm64"
}

variable "lambda_memory_size" {
  description = "The amount of memory to allocate to the lambda function"
  type        = number
  default     = 256
}

variable "cloudwatch" {
  description = "The cloudwatch configuration"
  type = object({
    ## The KMS key id to use for encrypting the log group
    kms_key_id = optional(string, null)
    ## The retention period for the log group
    retention_in_days = optional(number, 7)
    ## The class of the log group
    log_group_class = optional(string, "STANDARD")
  })
  default = {
    # The KMS key id to use for encrypting the log group
    kms_key_id = null
    # The retention period for the log group
    retention_in_days = 7
    # The class of the log group
    log_group_class = "STANDARD"
  }
}

variable "container_image" {
  description = "The image to use for the container"
  type        = string
  default     = "ghcr.io/ekristen/aws-nuke"
}

variable "container_image_tag" {
  description = "The tag to use for the container image"
  type        = string
  default     = "v3.26.0-2-g672408a-amd64"
}

variable "log_group_kms_key_id" {
  description = "The KMS key id to use for encrypting the log group"
  type        = string
  default     = null
}

variable "configuration_secret_name_prefix" {
  description = "The prefix to use for AWS Secrets Manager secrets to store the nuke configuration"
  type        = string
  default     = "/lza/configuration/nuke"
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
