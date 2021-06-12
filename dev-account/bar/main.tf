variable "dependency" {
    type = string
}

output "bar" {
  value = var.dependency
}

