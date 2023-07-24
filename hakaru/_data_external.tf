data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  exclude_names = ["ap-northeast-1b"]
}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}
