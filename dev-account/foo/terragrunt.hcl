include {
    path = find_in_parent_folders()
}

terraform {
    source = "${get_terragrunt_dir()}///"
}

dependency "bar" {
    config_path = "${get_terragrunt_dir()}/../bar"
}

inputs = {
    dependency = dependency.bar.outputs.random_value
}
