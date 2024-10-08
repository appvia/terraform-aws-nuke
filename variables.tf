
variable "create_kms_key" {
  description = "Indicates if a KMS key should be created for the log group"
  type        = bool
  default     = false
}

variable "enabled" {
  description = "Indicates the scheduled task should be enabled, else we cofingure the task to be disabled"
  type        = bool
  default     = true
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

variable "existing_vpc" {
  description = "When reusing an existing network, these are details of the network to use"
  type = object({
    vpc_id = string
    # The security group id to use when not creating a new network 
    security_group_id = optional(string, "")
    # The subnet mask for private subnets, when creating the network i.e subnet-id => 10.90.0.0/24
    private_subnet_ids = optional(list(string), [])
    # The ids of the private subnets to use when not creating a new network 
  })
  default = null
}

variable "log_group_name" {
  description = "The name of the log group to create"
  type        = string
  default     = "nuke"
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
  default = null
}

variable "network" {
  description = "The network to use for the endpoints and optinal resolvers"
  type = object({
    availability_zones = optional(number, 2)
    # Indicates if we should create a new network or reuse an existing one
    enable_default_route_table_association = optional(bool, true)
    # Whether to associate the default route table  
    enable_default_route_table_propagation = optional(bool, true)
    # Whether to propagate the default route table
    ipam_pool_id = optional(string, null)
    # The id of the ipam pool to use when creating the network
    name = optional(string, "nuke")
    # The name of the network to create
    private_netmask = optional(number, 28)
    # The ids of the private subnets to if we are reusing an existing network
    transit_gateway_id = optional(string, "")
    ## The transit gateway id to use for the network
    vpc_cidr = optional(string, "")
    # The vpc id to use when reusing an existing network 
    vpc_netmask = optional(number, null)
    # When using ipam this the netmask to use for the VPC
  })
  default = null
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
