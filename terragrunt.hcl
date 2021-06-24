locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "null.hcl"), { locals = { region = "us-west-2" } })

  account_name = local.account_vars.locals.account_name
  region       = local.region_vars.locals.region

  tf_state_bucket_name = "${local.account_name}-${local.region}-tf-state"
  tf_state_locking_db_table_name = "tf-state-locks"
  
  provider_switches = merge(
    read_terragrunt_config(find_in_parent_folders("provider_switches.hcl", "null.hcl"), {}),
    read_terragrunt_config("provider_switches.hcl", {})
  )

  before_hook = <<-EOF
  if [[ -z $SKIP_TFENV ]]; then \
    count=`ls -1 "*.tf" 2>/dev/null | wc -l`
    if [ $count != 0 ]; then \
      echo Found Terraform files
      echo Scanning Terraform files for Terraform binary version constraint
      tfenv use min-required || tfenv install min-required \
      && tfenv use min-required
    fi
  else
    echo Skip scanning Terraform files for Terraform binary version constraint
    echo "Terraform Version: $(tfenv version-name)";
  fi
  EOF
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

remote_state {
  backend = "s3"
  config = {
    bucket         = local.tf_state_bucket_name
    key            = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table = local.tf_state_locking_db_table_name
    encrypt        = true
    region         = local.region
  }
  generate = {
    path      = "backend.tf"
    if_exists = "skip"
  }
}

inputs = merge(
  local.account_vars.locals, 
  local.region_vars.locals, 
  {
    tf_state_bucket_name = local.tf_state_bucket_name
    tf_state_locking_db_table_name = local.tf_state_locking_db_table_name
  }
)