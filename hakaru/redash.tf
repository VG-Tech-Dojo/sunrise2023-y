data "local_file" "redash_user_data" {
  filename = "${path.cwd}/_files/redash_user_data.sh"
}

resource "aws_instance" "redash" {
  // https://redash.io/help/open-source/setup#aws
  ami                                  = "ami-060741a96307668be"
  instance_type                        = "t2.small"
  ebs_optimized                        = false
  monitoring                           = true
  disable_api_termination              = true
  instance_initiated_shutdown_behavior = "stop"
  tenancy                              = "default"
  key_name                             = var.AWS_KEYPAIR_NAME
  iam_instance_profile                 = aws_iam_instance_profile.redash.name
  user_data                            = data.local_file.redash_user_data.content

  root_block_device {
    volume_type           = "gp2"
    delete_on_termination = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.redash.id
  }

  tags = {
    Name = "redash"
  }

  volume_tags = {
    Name = "redash"
  }

  lifecycle {
    prevent_destroy = true
  }

}

resource "aws_eip" "redash" {
  domain = "vpc"

  tags = {
    Name = "redash"
  }
}

resource "aws_eip_association" "redash" {
  instance_id   = aws_instance.redash.id
  allocation_id = aws_eip.redash.id
}

resource "aws_network_interface" "redash" {
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.redash.id]

  tags = {
    Name = "redash"
  }
}

# security group

resource "aws_security_group" "redash" {
  name   = "redash"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "redash"
  }
}

resource "aws_security_group_rule" "redash_ingress_http" {
  security_group_id = aws_security_group.redash.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "redash_egress_all" {
  security_group_id = aws_security_group.redash.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
