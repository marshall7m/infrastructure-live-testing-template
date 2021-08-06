locals {
    account_name = read_terragrunt_config(find_in_parent_folders("dir_map.hcl"), "DEFAULT")["${path_relative_to_include()}"]
}