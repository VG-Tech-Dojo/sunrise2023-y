resource "aws_db_instance" "hakaru" {
  identifier                          = "hakaru"
  instance_class                      = "db.t4g.micro"
  storage_type                        = "gp2"
  allocated_storage                   = 10
  deletion_protection                 = true
  engine                              = "mysql"
  engine_version                      = "8.0"
  allow_major_version_upgrade         = false
  auto_minor_version_upgrade          = false
  option_group_name                   = aws_db_option_group.hakaru.name
  parameter_group_name                = aws_db_parameter_group.hakaru.name
  apply_immediately                   = false
  db_name                             = "hakaru"
  username                            = "root"
  password                            = "password"
  port                                = 3306
  backup_retention_period             = 0
  backup_window                       = "20:00-20:30"         // 05:00-05:30 JST
  maintenance_window                  = "Sun:21:00-Sun:21:30" // Mon:06:00-Mon:06:30 JST
  copy_tags_to_snapshot               = true
  skip_final_snapshot                 = true
  multi_az                            = true
  db_subnet_group_name                = aws_db_subnet_group.hakaru.name
  vpc_security_group_ids              = [aws_security_group.db.id]
  publicly_accessible                 = false
  iam_database_authentication_enabled = false
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring.arn

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [engine_version, password] // 作成後に手動で変更してtfstateには残らないようにする
  }
}

resource "aws_db_subnet_group" "hakaru" {
  name       = "hakaru"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_parameter_group" "hakaru" {
  name   = "hakaru"
  family = "mysql8.0"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  # https://dev.mysql.com/doc/refman/8.0/ja/charset-unicode-utf8.html
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_general_ci"
  }

  parameter {
    name         = "character-set-client-handshake"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "skip-character-set-client-handshake"
    value        = "0"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "0.5"
  }
}

resource "aws_db_option_group" "hakaru" {
  name                 = "hakaru"
  engine_name          = "mysql"
  major_engine_version = "8.0"
}

# security group

resource "aws_security_group" "db" {
  name   = "db"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "db_ingress" {
  security_group_id = aws_security_group.db.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}

resource "aws_security_group_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  type              = "egress"
  protocol          = "-1"
  to_port           = 0
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# iam

resource "aws_iam_role" "rds_monitoring" {
  name               = "rds-monitoring"
  path               = "/hakaru/"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json
}

resource "aws_iam_role_policy_attachment" "rds_enhance_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# kms

resource "aws_kms_key" "rds" {
  description = "hakaru rds encryption key"
}

resource "aws_kms_alias" "rds" {
  name          = "alias/hakaru/rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ssm

# NOTE: パスワードの保存先。内容自体にはterraformは関知しない

resource "aws_ssm_parameter" "rds_root_password" {
  name        = "/hakaru/rds/root/password"
  description = "hakaru rds password for root user"
  type        = "SecureString"
  value       = "password"
  key_id      = aws_kms_alias.rds.id

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]  // 作成後に手動で変更してtfstateには残らないようにする
  }
}

resource "aws_ssm_parameter" "rds_hakaru_password" {
  name        = "/hakaru/rds/hakaru/password"
  description = "hakaru rds password for hakaru application user"
  type        = "SecureString"
  value       = "password"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]  // 作成後に手動で変更してtfstateには残らないようにする
  }
}

resource "aws_ssm_parameter" "rds_redash_password" {
  name        = "/hakaru/rds/redash/password"
  description = "hakaru rds password for redash user"
  type        = "SecureString"
  value       = "password"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]  // 作成後に手動で変更してtfstateには残らないようにする
  }
}
