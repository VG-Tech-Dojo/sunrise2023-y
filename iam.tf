resource "aws_iam_user" "participant" {
  for_each = toset([])
  name     = each.value
  path     = "/participant/"
}

resource "aws_iam_user" "staff" {
  for_each = toset([])
  name = each.value
  path = "/staff/"
}

/*
 * admin group
 */

resource "aws_iam_group" "admin" {
  name = "admin"
  path = "/user/"
}

resource "aws_iam_group_policy_attachment" "admin" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "billing" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

resource "aws_iam_group_membership" "admin" {
  name  = "admin"
  group = aws_iam_group.admin.name
  users = [for k, v in aws_iam_user.staff : v.name]

  lifecycle {
    ignore_changes = [users]
  }
}

/*
 * staff switch role
 */

module "aws_iam_switchrole" {
  source       = "./_local_modules/aws_iam_switchrole"
  account_keys = var.aws_account_names
  accounts     = local.aws_accounts
  role_name_prefix = "sunrise2023"
}
