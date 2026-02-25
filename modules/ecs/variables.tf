
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
    # The schedule to run the task
    schedule = string
  }))
}

variable "cloudwatch_log_group_prefix" {
  description = "The prefix to use for the CloudWatch log group"
  type        = string
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The retention period for the CloudWatch log group"
  type        = number
}

variable "cloudwatch_log_group_class" {
  description = "The class of the CloudWatch log group"
  type        = string
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The KMS key id to use for encrypting the log group"
  type        = string
}

variable "container_image" {
  description = "The image to use for the container"
  type        = string
}

variable "container_image_tag" {
  description = "The tag to use for the container image"
  type        = string
}

variable "container_cpu" {
  description = "The amount of CPU to allocate to the container"
  type        = number
}

variable "container_memory" {
  description = "The amount of memory to allocate to the container"
  type        = number
}

variable "enable_container_insights" {
  description = "Indicates if container insights should be enabled for the cluster"
  type        = bool
}

variable "assign_public_ip" {
  description = "Indicates if the task should be assigned a public IP"
  type        = bool
}

variable "subnet_ids" {
  description = "The subnet id's to use for the nuke service"
  type        = list(string)
}

variable "secret_arns" {
  description = "A map of task name to the ARN of the SecretsManager secret holding the nuke configuration"
  type        = map(string)
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
