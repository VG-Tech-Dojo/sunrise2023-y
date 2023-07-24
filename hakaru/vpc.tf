module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.1.0" // https://github.com/terraform-aws-modules/terraform-aws-vpc/releases
  name                 = "hakaru"
  cidr                 = local.vpc_cidr_block
  azs                  = data.aws_availability_zones.available.names
  enable_dns_hostnames = true
  enable_nat_gateway   = true

  public_subnets = [
    cidrsubnet(local.vpc_cidr_block, 8, 1),
    cidrsubnet(local.vpc_cidr_block, 8, 3),
    cidrsubnet(local.vpc_cidr_block, 8, 5),
  ]

  private_subnets = [
    cidrsubnet(local.vpc_cidr_block, 8, 11),
    cidrsubnet(local.vpc_cidr_block, 8, 13),
    cidrsubnet(local.vpc_cidr_block, 8, 15),
  ]
}

resource "aws_default_security_group" "hakaru" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${module.vpc.name}-default"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [local.vpc_cidr_block]
  }

  tags = {
    Name = "${module.vpc.name}-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]] // not support ap-northeast-1d
  private_dns_enabled = true

  tags = {
    Name = "ssm"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true

  tags = {
    Name = "ec2messages"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true

  tags = {
    Name = "ec2"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true

  tags = {
    Name = "ssmmessages"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(module.vpc.public_route_table_ids, module.vpc.private_route_table_ids)

  tags = {
    Name = "s3"
  }
}
