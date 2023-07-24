module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0" // https://github.com/terraform-aws-modules/terraform-aws-vpc/releases

  create_vpc = false

  manage_default_vpc               = true
  default_vpc_name                 = "default"
  default_vpc_enable_dns_hostnames = true
}
