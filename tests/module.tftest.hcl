
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = [
        "eu-west-1a",
        "eu-west-1b",
        "eu-west-1c"
      ]
    }
  }
}

run "basic" {
  command = plan

  variables {
    account_id = "123456789012"
    region     = "eu-west-1"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]
    tags = {
      "Environment" = "Testing"
      "GitRepo"     = "https://github.com/appvia/terraform-aws-dns"
    }

    tasks = {
      "nuke" = {
        configuration     = file("./examples/basic/assets/nuke-config.yml.example")
        description       = "Nuke the account"
        dry_run           = false
        retention_in_days = 7
        schedule          = "cron(0 0 * * ? *)"
      }
    }
  }
}
