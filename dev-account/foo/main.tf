variable "dependency" {
    type = string
}

output "foo" {
  value = var.dependency
}

