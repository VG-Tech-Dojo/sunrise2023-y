variable AWS_DEFAULT_REGION {}
variable AWS_PROFILE {}
variable AWS_KEYPAIR_NAME {}
variable AWS_SSM_KEYPAIR_PRIVATE_KEY {}

variable "aws_account_names" {
  type = list(string)
}

variable "aws_account_numbers" {
  type      = list(string)
  sensitive = true
}

locals {
  vpc_cidr_block = "10.1.0.0/16"
}
