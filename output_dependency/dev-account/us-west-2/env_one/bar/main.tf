variable "bar" {
    type = string
}

output "bar" {
  value = var.bar
}

variable "global" {
    type = string
}

output "global" {
  value = var.global
}