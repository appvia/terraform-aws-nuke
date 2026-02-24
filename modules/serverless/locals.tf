
locals {
  ## The local account id
  account_id = var.account_id
  ## The region the resources are being provisioned in
  region = var.region
  ## The configuration values passed to the rendered template 
  configuration_data = {
    account_id = local.account_id
    region     = local.region
  }
}

