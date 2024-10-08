
#mock_provider "aws" {
#  mock_data "aws_availability_zones" {
#    defaults = {
#      names = [
#        "eu-west-1a",
#        "eu-west-1b",
#        "eu-west-1c"
#      ]
#    }
#  }
#}
#
#run "basic" {
#  command = plan
#
#  variables {
#    nuke_configuration = "./examples/basic/assets/nuke-config.yml.example"
#    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
#    tags = {
#      "Environment" = "Testing"
#      "GitRepo"     = "https://github.com/appvia/terraform-aws-dns"
#    }
#  }
#}
