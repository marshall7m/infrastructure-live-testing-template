include {
    path = find_in_parent_folders()
}

terraform {
    source = "${get_terragrunt_dir()}///"
}

dependency "baz" {
    config_path = "${get_terragrunt_dir()}/../baz"
}

inputs = {
    dependency = dependency.baz.outputs.random_value
}
