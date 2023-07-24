terraform {
  required_version = ">= 1.5.0"
}

resource "aws_iam_role" "this" {
  for_each              = toset(var.account_keys)
  name                  = "${var.role_name_prefix}-${each.value}"
  path                  = "/switchrole/"
  force_detach_policies = true
  max_session_duration  = 12 * 60 * 60

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]

        Principal = {
          AWS = "arn:aws:iam::${var.accounts[each.value]}:root"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin" {
  for_each   = toset([for _, v in aws_iam_role.this : v.name])
  role       = each.value
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "billing" {
  for_each   = toset([for _, v in aws_iam_role.this : v.name])
  role       = each.value
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}
