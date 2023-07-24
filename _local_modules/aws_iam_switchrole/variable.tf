# https://github.com/hashicorp/terraform/issues/27180

variable "account_keys" {
  type = list(string)
}

variable "accounts" {
  type      = map(string)
  sensitive = true
}

variable "role_name_prefix" {
  type = string
  default = "switchrole"
}
