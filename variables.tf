
variable "name" {
  description = "The name of the nuke service"
  type        = string
  default     = "nuke-service"
}

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

variable "tasks" {
  description = "A collection of nuke tasks to run and when to run them"
  type = map(object({
    additional_permissions = optional(map(object({
      policy = string
    })), {})
    configuration_file      = string
    description             = string
    dry_run                 = optional(bool, true)
    permission_boundary_arn = optional(string, null)
    permission_arns         = optional(list(string), ["arn:aws:iam::aws:policy/AdministratorAccess"])
    retention_in_days       = optional(number, 7)
    schedule                = string
  }))

  ## The task key must be all lowercase and contain only alpha characters
  validation {
    condition     = alltrue([for task in keys(var.tasks) : can(regex("^[a-z\\_]+$", task))])
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

variable "container_cpu" {
  description = "The amount of CPU to allocate to the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "The amount of memory to allocate to the container"
  type        = number
  default     = 512
}

variable "enable_container_insights" {
  description = "Indicates if container insights should be enabled for the cluster"
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Indicates if the task should be assigned a public IP"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "The subnet id's to use for the nuke service"
  type        = list(string)
}

variable "log_group_name_prefix" {
  description = "The name of the log group to create"
  type        = string
  default     = "/lza/services/nuke"
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

variable "iam_execution_role_prefix" {
  description = "The prefix to use for the IAM execution roles used by the tasks"
  type        = string
  default     = "nuke-execution-"
}

variable "iam_task_role_prefix" {
  description = "The prefix to use for the IAM tasg roles used by the tasks"
  type        = string
  default     = "nuke-"
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
}
