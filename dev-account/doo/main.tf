resource "random_id" "test" {
  byte_length = 8
}

output "random_value" {
  value = random_id.test.id
}