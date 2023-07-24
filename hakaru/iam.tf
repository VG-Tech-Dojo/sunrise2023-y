data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

# hakaru

data "aws_iam_policy_document" "hakaru" {
  statement {
    sid       = "ArtifactsReadOnly"
    effect    = "Allow"
    actions   = ["s3:List*", "s3:Get*"]
    resources = [aws_s3_bucket.artifacts.arn]
  }

  statement {
    sid       = "DescribeRDS"
    effect    = "Allow"
    actions   = ["rds:DescribeDBInstances"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = [aws_ssm_parameter.rds_hakaru_password.arn]

  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.target_key_arn]
  }
}

resource "aws_iam_role" "hakaru" {
  name               = "hakaru"
  path               = "/hakaru/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "hakaru_ssm" {
  role       = aws_iam_role.hakaru.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "hakrau_ssm_manager" {
  role       = aws_iam_role.hakaru.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "hakaru_cw" {
  role       = aws_iam_role.hakaru.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "hakaru_app" {
  role   = aws_iam_role.hakaru.name
  policy = data.aws_iam_policy_document.hakaru.json
}

resource "aws_iam_instance_profile" "hakaru" {
  name = "hakaru"
  path = "/hakaru/"
  role = aws_iam_role.hakaru.name
}

# redash

resource "aws_iam_role" "redash" {
  name               = "redash"
  path               = "/hakaru/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "redash_ssm" {
  role       = aws_iam_role.redash.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "redash_ssm_manager" {
  role       = aws_iam_role.redash.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "redash" {
  name = "redash"
  path = "/hakaru/"
  role = aws_iam_role.redash.name
}
