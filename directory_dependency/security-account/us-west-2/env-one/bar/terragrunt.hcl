include {
    path = find_in_parent_folders()
}

terraform {
    source = "${get_terragrunt_dir()}///"
}

dependencies {
  paths = ["../baz", "../../global"]
}

inputs = {
    is_mod = get_env("IS_MOD", false)
}