remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    path = "${get_env("TESTING_LOCAL_PARENT_TF_STATE_DIR")}/${path_relative_to_include()}/terraform.tfstate"
  }
}