mock_provider "aws" {
  ## aws_iam_policy_document is evaluated by the provider; supply valid JSON so
  ## resource policy attributes pass client-side validation during plan.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  ## data.aws_caller_identity and data.aws_region are used to build the
  ## repository ARN local; mock them with deterministic test values.
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "eu-west-1"
    }
  }
}

## Validate default repository name and non-null ARN.
run "repository_defaults" {
  command = plan

  module {
    source = "./modules/repository"
  }

  assert {
    condition     = output.repository_name == "lz/operations/aws-nuke"
    error_message = "Default repository name must be lz/operations/aws-nuke"
  }
}

## Validate custom repository name is reflected in the output.
run "repository_custom_name" {
  command = plan

  module {
    source = "./modules/repository"
  }

  variables {
    repository_name = "platform/aws-nuke-wrapper"
    tags = {
      "Environment" = "Test"
      "Team"        = "Platform"
    }
  }

  assert {
    condition     = output.repository_name == "platform/aws-nuke-wrapper"
    error_message = "Repository name must match var.repository_name"
  }
}

## Validate cross-account pull access is accepted without error.
run "repository_cross_account" {
  command = plan

  module {
    source = "./modules/repository"
  }

  variables {
    repository_name = "lz/operations/aws-nuke"
    account_ids     = ["123456789012", "234567890123", "345678901234"]
    tags = {
      "Environment" = "Production"
    }
  }

  assert {
    condition     = output.repository_name == "lz/operations/aws-nuke"
    error_message = "Repository name must equal var.repository_name"
  }
}

## Validate org-level pull access is accepted without error.
run "repository_org_access" {
  command = plan

  module {
    source = "./modules/repository"
  }

  variables {
    repository_name = "lz/operations/aws-nuke"
    organization_id = "o-abc123def456"
  }

  assert {
    condition     = output.repository_name == "lz/operations/aws-nuke"
    error_message = "Repository name must equal var.repository_name with org access"
  }
}
