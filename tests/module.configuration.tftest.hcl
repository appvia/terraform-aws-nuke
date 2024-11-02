
run "module_configuration" {
  command = plan

  module {
    source = "./modules/configuration"
  }

  variables {
    accounts = [123456789012, 123456789013]
    regions  = ["us-east-1", "us-west-2"]

    presets = {
      "default" = {
        "IAMRole" = [
          {
            property = "roleName"
            type     = "regex"
            value    = "^AWSControlTower.*"
          }
        ]
      }
    }

    filters = [
      {
        property = "tag:Environment"
        type     = "string"
        value    = "Sandbox"
      },
      {
        property = "tag:Owner"
        type     = "string"
        value    = "Support"
      }
    ]

    include_presets = {
      enable_control_tower     = true
      enable_cost_intelligence = true
      enable_landing_zone      = true
    }
  }
}
