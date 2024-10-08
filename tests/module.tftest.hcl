
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
    network = {
      vpc_cidr           = "10.90.0.0/21"
      transit_gateway_id = "tgw-04ad8f026be8b7eb6"
    }
    nuke_configuration = "./examples/basic/assets/nuke-config.yml.example"
    tags = {
      "Environment" = "Testing"
      "GitRepo"     = "https://github.com/appvia/terraform-aws-dns"
    }
  }
}
