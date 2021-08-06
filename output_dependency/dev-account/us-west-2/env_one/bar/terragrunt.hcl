include {
    path = find_in_parent_folders()
}

terraform {
    source = "${get_terragrunt_dir()}///"
}

dependency "baz" {
    config_path = "${get_terragrunt_dir()}/../baz"
}

dependency "global" {
    config_path = "${get_terragrunt_dir()}/../../global"
}

inputs = {
    bar = dependency.baz.outputs.baz
    global = dependency.global.outputs.global
}
