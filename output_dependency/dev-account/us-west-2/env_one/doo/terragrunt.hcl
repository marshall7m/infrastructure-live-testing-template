include {
    path = find_in_parent_folders()
}

terraform {
    source = "${get_terragrunt_dir()}///"
}

dependency "global" {
    config_path = "${get_terragrunt_dir()}/../../global"
}

inputs = {
    doo = "doo"
    global = dependency.global.outputs.global
}
