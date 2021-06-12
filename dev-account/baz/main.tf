variable "value" {
  description = "input value for AWS SSM parameter store value"
  type = string
}

resource "aws_ssm_parameter" "test" {
  name  = "mut-terraform-aws-infrastructure-live-ci"
  type  = "String"
  value = var.value
}

output "ssm_param" {
  value = aws_ssm_parameter.test.value
}
