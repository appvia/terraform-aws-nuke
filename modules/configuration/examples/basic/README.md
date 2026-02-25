# Configuration Module -- Basic Example

## Introduction

This example demonstrates using the [configuration](../../) sub-module to render an aws-nuke YAML configuration file. It targets two accounts across two regions, applies tag-based filters, configures a preset for IAM roles matching Control Tower naming, and customises the excluded resource list.

## Features

- **Multi-account, multi-region** -- targets accounts `123456789012` and `123456789013` across `us-east-1` and `us-west-2`.
- **Tag-based global filters** -- protects resources tagged `Environment=Sandbox` and `Owner=Support` from deletion.
- **Preset filters** -- defines a `landing_zone` preset filtering IAM roles matching `^AWSControlTower.*`.
- **Exclusion overrides** -- adds `WorkSpacesWorkspace` to the exclusion list and removes `IAMUser` from it.
- **Built-in filter presets** -- enables Control Tower, Cost Intelligence, and Landing Zone filters.

## Usage

```hcl
module "configuration" {
  source = "github.com/appvia/terraform-aws-nuke//modules/configuration?ref=main"

  accounts = ["123456789012", "123456789013"]
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
    }
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configuration"></a> [configuration](#output\_configuration) | The rendered configuration file for the nuke service |
<!-- END_TF_DOCS -->