
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

variable "name" {
  description = "The name of the instance (used to prefix the resources)"
  type        = string
  default     = "lz-nuke"
}

variable "ecs" {
  description = "Indicates if the ECS cluster should be created"
  type = object({
    ## Associate a public IP address to the task
    assign_public_ip = optional(bool, false)
    ## The prefix to use for the CloudWatch log group
    cloudwatch_log_group_prefix = optional(string, "/lz/services/nuke")
    ## The retention period for the CloudWatch log group (in days)
    cloudwatch_log_group_retention_in_days = optional(number, 7)
    ## The class of the CloudWatch log group
    cloudwatch_log_group_class = optional(string, "STANDARD")
    ## The KMS key id to use for encrypting the log group
    cloudwatch_log_group_kms_key_id = optional(string, null)
    ## The amount of memory to allocate to the container
    container_memory = optional(number, 512)
    ## The amount of CPU to allocate to the container
    container_cpu = optional(number, 256)
    ## Enable container insights
    enable_container_insights = optional(bool, false)
    ## The subnet ids to use for the ECS cluster
    subnet_ids = list(string)
  })
  default = null
}

variable "lambda" {
  description = "Indicates if the Lambda function should be created"
  type = object({
    # The architecture to use for the Lambda function
    architecture = optional(string, "arm64")
    # The memory size to use for the Lambda function
    memory_size = optional(number, 256)
    # The timeout to use for the Lambda function
    timeout = optional(number, 900)
    ## The cloudwatch log group retention in days
    cloudwatch_log_group_retention_in_days = optional(number, 7)
    ## The cloudwatch log group class
    cloudwatch_log_group_class = optional(string, "STANDARD")
    ## The cloudwatch log group KMS key id
    cloudwatch_log_group_kms_key_id = optional(string, null)
  })
  default = null
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

  ## The task must have a configuration
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

variable "kms_administrator_role_name" {
  description = "The name of the role to use as the administrator for the KMS key (defaults to account root)"
  type        = string
  default     = ""
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

variable "configuration_secret_name_prefix" {
  description = "The prefix to use for AWS Secrets Manager secrets to store the nuke configuration"
  type        = string
  default     = "/lz/services/nuke"
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
