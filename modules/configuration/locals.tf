
locals {
  ## All the presets to include in the configuration
  presets = merge(
    var.include_presets.enable_control_tower ? { "control_tower" = local.control_tower_presets } : {},
    var.include_presets.enable_cost_intelligence ? { "cost_intelligence" = local.cost_intelligence_presets } : {},
    var.include_presets.enable_landing_zone ? { "landing_zone" = local.landing_zone_present } : {},
    var.presets
  )

  ## All the resources, including the filters to apply to them 
  resources = merge({
    for resource in var.included : resource => var.filters
  })

  ## Render the configuration file
  configuration = templatefile("${path.module}/assets/config.yml", {
    accounts  = var.accounts
    blocklist = var.blocklist
    excluded  = var.excluded
    included  = local.resources
    presets   = local.presets
    regions   = var.regions
  })

  #accounts:
  #  %{ for account in accounts ~}
  #  ${account}:
  #    presets:
  #      %{ for preset_name, preset_filters in presets ~}
  #      - ${preset_name}
  #      %{ endfor ~}
  #
  #    filters:
  #      %{ for resource, filters in included ~}
  #      ${resource}:
  #        %{ for filter in filters ~}
  #        - property: ${filter.property}
  #          type: ${filter.type}
  #          value: ${filter.value}
  #        %{ endfor ~}
  #      %{ endfor ~}
  #  %{ endfor ~}
  #
  ## The filters for control tower
  control_tower_presets = {
    CloudWatchLogsLogGroup = [
      {
        property = "logGroupName"
        type     = "contains"
        value    = "aws-landing-zone"
      }
    ]
    IAMRole = [
      {
        property = "roleName"
        type     = "regex"
        value    = "^AWSControlTower.*"
      },
      {
        property = "roleName"
        type     = "regex"
        value    = "^aws-controltower.*"
      }
    ]
    LambdaFunction = [
      {
        property = "functionName"
        type     = "regex"
        value    = "^aws-controltower-NotificationForwarder$"
      }
    ]
    SNSSubscription = [
      {
        property = "topicArn"
        type     = "regex"
        value    = "^arn:aws:sns:.*:.*:aws-controltower.*"
      }
    ]
    SNSTopic = [
      {
        property = "topicArn"
        type     = "contains"
        value    = "aws-controltower"
      }
    ]
  }

  ## Cost Intelligence Presets 
  cost_intelligence_presets = {
    IAMRole = [
      {
        property = "Name"
        type     = "regex"
        value    = "^CID-DC.*"
      }
    ]
  }

  ## The filters for the landing zone 
  landing_zone_present = {
    CloudWatchLogsLogGroup = [
      {
        property = "logGroupName"
        type     = "contains"
        value    = "AWSAccelerator"
      },
      {
        property = "logGroupName"
        type     = "regex"
        value    = "^lza-"
      },
      {
        property = "logGroupName"
        type     = "regex"
        value    = "^/lza-"
      },
      {
        property = "logGroupName"
        type     = "regex"
        value    = "^/aws/lambda/lza-"
      }
    ]
    IAMInstanceProfile = [
      {
        property = "Name"
        type     = "regex"
        value    = "^lza-.*"
      }
    ]
    IAMInstanceProfileRole = [
      {
        property = "InstanceProfile"
        type     = "regex"
        value    = "^AWSAccelerator.*"
      },
      {
        property = "InstanceProfile"
        type     = "regex"
        value    = "^lza-.*"
      }
    ]
    IAMRole = [
      {
        property = "Name"
        type     = "regex"
        value    = "^AWSAccelerator.*"
      },
      {
        property = "Name"
        type     = "regex"
        value    = "^lza-.*"
      },
      {
        property = "Name"
        type     = "contains"
        value    = "CrossAccount"
      },
      {
        property = "Name"
        type     = "regex"
        value    = "^stacksets-exec-.*"
      }
    ]
    KMSAlias = [
      {
        property = "Name"
        type     = "regex"
        value    = "^alias/accelerator/.*"
      },
      {
        property = "Name"
        type     = "regex"
        value    = "^alias/lza/.*"
      }
    ]
    KMSKey = [
      {
        property = "tag:Accelerator"
        type     = "exact"
        value    = "AWSAccelerator"
      },
      {
        property = "Name"
        type     = "regex"
        value    = "^lza-.*"
      }
    ]
    LambdaFunction = [
      {
        property = "Name"
        type     = "regex"
        value    = "^aws-accelerator-.*"
      },
      {
        property = "Name"
        type     = "regex"
        value    = "^lza-.*"
      }
    ]
    SSMParameter = [
      {
        property = "Name"
        type     = "regex"
        value    = "^/accelerator/AWSAccelerator.*"
      },
      {
        property = "Name"
        type     = "regex"
        value    = "^/lza/.*"
      }
    ]
    SNSSubscription = [
      {
        property = "ARN"
        type     = "regex"
        value    = "^arn:aws:sns:.*:.*:aws-accelerator.*"
      },
      {
        property = "ARN"
        type     = "regex"
        value    = "^arn:aws:sns:.*:.*:lza-.*"
      }
    ]
    SNSTopic = [
      {
        property = "Name"
        type     = "contains"
        value    = "lza-"
      },
      {
        property = "TopicARN"
        type     = "contains"
        value    = "lza-"
      }
    ]
  }
}
