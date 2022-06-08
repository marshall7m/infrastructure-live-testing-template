locals {
  backend = get_env("TG_BACKEND")
  root_dir = get_env("ROOT_TF_STATE_DIR", "")
  path = "${local.root_dir}${path_relative_to_include()}/terraform.tfstate"

  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "null.hcl"), { locals = { region = "us-west-2" } })
  region       = local.region_vars.locals.region

  backend_cfgs = {
    local = {
      path = local.path
    },
    s3 = {
      bucket = get_env("TG_S3_BUCKET", "testing-infrastructure-live")
      key    = local.path
      region = local.region
      encrypt = true
      disable_bucket_update = false
    }
  }
}

remote_state {
  backend = local.backend
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = lookup(local.backend_cfgs, local.backend, {})
}