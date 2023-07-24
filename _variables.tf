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
  aws_accounts = zipmap(var.aws_account_names, var.aws_account_numbers)
}
