
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

variable "log_group_name_prefix" {
  description = "The name of the log group to create"
  type        = string
}

variable "log_group_kms_key_id" {
  description = "The KMS key id to use for encrypting the log group"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
}
