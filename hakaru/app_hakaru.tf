# loadbalancer

resource "aws_lb" "hakaru" {
  name                             = "hakaru"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.hakaru_lb.id]
  subnets                          = module.vpc.public_subnets
  enable_deletion_protection       = true
  idle_timeout                     = 60
  enable_cross_zone_load_balancing = true
  enable_http2                     = false
  ip_address_type                  = "ipv4"
}

resource "aws_lb_listener" "hakaru_http" {
  load_balancer_arn = aws_lb.hakaru.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hakaru.arn
  }
}

resource "aws_lb_target_group" "hakaru" {
  name                 = "hakaru"
  port                 = 8081
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 300
  target_type          = "instance"

  health_check {
    interval            = 30
    path                = "/ok"
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# auto scaling group

resource "aws_launch_template" "hakaru" {
  name_prefix                          = "hakaru-"
  image_id                             = "ami-0cc75a8978fbbc969"
  instance_type                        = "c5.large"
  ebs_optimized                        = true
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = var.AWS_KEYPAIR_NAME

  user_data = base64encode(<<EOF
#!/bin/bash

cd /root/hakaru || exit 2
make deploy ARTIFACTS_COMMIT=latest
EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.hakaru.name
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [aws_security_group.hakaru.id]
  }

  monitoring {
    enabled = true
  }

  placement {
    tenancy = "default"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "hakaru"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "hakaru"
    }
  }

  lifecycle {
    ignore_changes = [
      image_id,
      user_data,
    ]
  }
}

resource "aws_autoscaling_group" "hakaru" {
  name                      = "hakaru"
  max_size                  = 0
  min_size                  = 0
  desired_capacity          = 0
  default_cooldown          = 180
  health_check_grace_period = 180
  health_check_type         = "EC2"
  force_delete              = true
  termination_policies      = ["OldestLaunchTemplate", "OldestInstance"]
  vpc_zone_identifier       = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.hakaru.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      max_size,
      min_size,
      desired_capacity,
      load_balancers,
      target_group_arns,
    ]
  }
}

resource "aws_autoscaling_attachment" "hakaru" {
  autoscaling_group_name = aws_autoscaling_group.hakaru.name
  lb_target_group_arn   = aws_lb_target_group.hakaru.arn
}

# security group

resource "aws_security_group" "hakaru_lb" {
  name   = "hakaru-lb"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "hakaru_lb_ingress_http" {
  security_group_id = aws_security_group.hakaru_lb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "hakaru_lb_egress_all" {
  security_group_id = aws_security_group.hakaru_lb.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "hakaru" {
  name   = "hakaru"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "hakaru"
  }
}

resource "aws_security_group_rule" "hakaru_ingress_http" {
  security_group_id = aws_security_group.hakaru.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8081
  to_port           = 8081
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "hakaru_egress_all" {
  security_group_id = aws_security_group.hakaru.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_cloudwatch_log_group" "messages" {
  name              = "/hakaru/var/log/messages"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "secure" {
  name              = "/hakaru/var/log/secure"
  retention_in_days = 7
}
