
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

variable "enable_deletion" {
  description = "Indicates the scheduled task will dry-run, log and report but not delete resources"
  type        = bool
  default     = false
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

variable "nuke_configuration" {
  description = "The YAML configuration to use for aws-nuke"
  type        = string
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

variable "log_group_name" {
  description = "The name of the log group to create"
  type        = string
  default     = null
}

variable "log_retention_in_days" {
  description = "The number of days to retain logs for"
  type        = number
  default     = 7
}

variable "log_group_kms_key_id" {
  description = "The KMS key id to use for encrypting the log group"
  type        = string
  default     = null
}

variable "configuration_secret_name" {
  description = "The name of the AWS Secrets Manager secret to store the configuration"
  type        = string
  default     = null
}

variable "task_role_permissions_arns" {
  description = "A list of permissions to attach to the IAM role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "task_role_permissions_boundary_arn" {
  description = "The boundary policy to attach to the IAM role"
  type        = string
  default     = null
}

variable "task_role_additional_policies" {
  description = "A map of inline policies to attach to the IAM role"
  type = map(object({
    policy = string
  }))
  default = {}
}

variable "schedule_expression" {
  description = "The schedule expression to use for the event rule"
  type        = string
  default     = "cron(0 0 * * ? *)"
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
}
