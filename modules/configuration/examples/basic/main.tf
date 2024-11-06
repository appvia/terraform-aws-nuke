#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  tags = {
    "Environment" = "Sandbox"
    "GitRepo"     = "https://github.com/appvia/terraform-aws-nuke"
    "Owner"       = "Support"
    "Product"     = "Sandbox"
  }
}

module "configuration" {
  source = "../.."

  accounts = [123456789012, 123456789013]
  regions  = ["us-east-1", "us-west-2"]

  presets = {
    "landing_zone" = {
      "IAMRole" = [
        {
          property = "roleName"
          type     = "regex"
          value    = "^AWSControlTower.*"
        }
      ]
    }
  }

  excluded = {
    add    = ["WorkSpacesWorkspace"]
    remove = ["IAMUser"]
  }

  filters = [
    {
      property = "tag:Environment"
      type     = "exact"
      value    = "Sandbox"
    },
    {
      property = "tag:Owner"
      type     = "exact"
      value    = "Support"
    }
  ]

  include_filters = {
    enable_control_tower     = true
    enable_cost_intelligence = true
    enable_landing_zone      = true
  }
}
