variable "dependency" {
    type = string
}

output "random_value" {
  value = var.dependency
}