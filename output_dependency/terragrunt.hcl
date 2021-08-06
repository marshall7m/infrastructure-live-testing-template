locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl", "null.hcl"), { locals = { account_name = basename(get_terragrunt_dir()) } })
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "null.hcl"), { locals = { region = "us-west-2" } })

  account_name = local.account_vars.locals.account_name
  region       = local.region_vars.locals.region
  
  provider_switches = merge(
    read_terragrunt_config(find_in_parent_folders("provider_switches.hcl", "null.hcl"), {}),
    read_terragrunt_config("provider_switches.hcl", {})
  )
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  contents  = <<-EOF
  %{ if try(local.provider_switches.locals.include_aws, false) }
  provider "aws" {
    region = "${local.region}"
    assume_role {
      role_arn = "${get_env("CI_ROLE_ARN", "")}"
    }
    profile = "${get_env("AWS_PROFILE", "")}"
  }
  %{ endif }
  EOF
}

terraform {
  before_hook "before_hook" {
    commands     = ["validate", "plan", "apply"]
    execute      = ["bash", "-c", local.before_hook]
  }
}

inputs = merge(
  local.account_vars.locals, 
  local.region_vars.locals
)