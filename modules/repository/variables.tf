
variable "account_ids" {
  description = "The account ids to allow access to the repository"
  type        = list(string)
  default     = []
}

variable "enable_scan_on_push" {
  description = "Indicates if the repository should enable image scanning on push"
  type        = bool
  default     = true
}

variable "immutable_exclusions" {
  description = "A collection of immutable exclusions to apply to the repository"
  type = list(object({
    ## The filter to apply to the exclusion
    filter = string
    ## The type of filter to apply to the exclusion
    filter_type = string
  }))
  default = []
}

variable "kms_key_id" {
  description = "The KMS key ID to use for the repository"
  type        = string
  default     = null
}

variable "organization_id" {
  description = "AWS Organization ID used to pull the nuke container image from the AWS ECR Public Gallery"
  type        = string
  default     = null
}

variable "repository_name" {
  description = "The name of the repository to use for the nuke container"
  type        = string
  default     = "lz/operations/aws-nuke"
}

variable "tags" {
  description = "Map of tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}