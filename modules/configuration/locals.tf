
locals {
  ## All the filters to include in the global configuration
  filters = concat(
    var.include_filters.enable_control_tower ? local.control_tower_filters : [],
    var.include_filters.enable_cost_intelligence ? local.cost_intelligence_filters : [],
    var.include_filters.enable_landing_zone ? local.landing_zone_filters : [],
    var.filters
  )

  ## All the resources to include in the configuration, removing any elements 
  ## that are in the excluded list
  included_resources = sort(distinct(concat(var.included.all, var.included.add)))

  ## All the resources to exclude from the configuration 
  excluded_resources = sort(
    setsubtract(distinct(concat(var.excluded.all, var.excluded.add)), var.excluded.remove)
  )

  ## All the resources, including the filters to apply to them 
  resources = merge({
    for resource in local.included_resources : resource => var.filters
  })

  ## Render the configuration file
  configuration = templatefile("${path.module}/assets/config.yml", {
    accounts  = sort(distinct(var.accounts))
    blocklist = sort(distinct(var.blocklist))
    global    = local.filters
    excluded  = local.excluded_resources
    included  = local.resources
    presets   = var.presets
    regions   = sort(distinct(var.regions))
  })

  ## The filters for control tower
  control_tower_filters = [
    {
      property = "logGroupName"
      type     = "regex"
      value    = ".*(aws-landing-zone|aws-controltower).*"
    },
    {
      property = "RoleName"
      type     = "regex"
      value    = "^(aws-controltower|AWSControlTower|AWSControlTowerExecution).*"
    },
    {
      property = "FunctionName"
      type     = "contains"
      value    = "aws-controltower"
    },
    {
      property = "TopicARN"
      type     = "contains"
      value    = "aws-controltower"
    },
    {
      property = "Name"
      type     = "regex"
      value    = "^aws-controltower.*"
    }
  ]

  ## Cost Intelligence filters 
  cost_intelligence_filters = [
    {
      property = "Name"
      type     = "regex"
      value    = "^CID-DC.*"
    }
  ]

  ## The filters for the landing zone 
  landing_zone_filters = [
    {
      property = "tag:Product"
      type     = "exact"
      value    = "LandingZone"
    },
    {
      property = "tag:Accelerator"
      type     = "exact"
      value    = "AWSAccelerator"
    },
    {
      property = "tag:aws:cloudformation:stack-name"
      type     = "regex"
      value    = "AWSAccelerator.*"
    },
    {
      property = "logGroupName"
      type     = "regex"
      value    = ".*(AWSAccelerator|lza).*"
    },
    {
      property = "Name"
      type     = "regex"
      value    = "(accelerator|lza|AWSAccelerator|stacksets-exec|CrossAccount)"
    },
    {
      property = "InstanceProfile"
      type     = "regex"
      value    = "^(AWSAccelerator|lza-).*"
    },
    {
      property = "ARN"
      type     = "regex"
      value    = ".*(aws-accelerator|lza-).*"
    },
    {
      property = "TopicARN"
      type     = "regex"
      value    = "lza-"
    }
  ]
}
