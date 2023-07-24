resource "aws_ssm_document" "default" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<DOC
{
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
        "s3BucketName": "${aws_s3_bucket.ssm.bucket}",
        "s3EncryptionEnabled": true,
        "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.ssm.name}",
        "cloudWatchEncryptionEnabled": true
    }
}
DOC
}

resource "aws_s3_bucket" "ssm" {
  bucket = "${var.AWS_PROFILE}-session-manager"
}

resource "aws_s3_bucket_public_access_block" "ssm" {
  bucket = aws_s3_bucket.ssm.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ssm" {
  bucket = aws_s3_bucket.ssm.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm" {
  bucket = aws_s3_bucket.ssm.id

  rule {
    id = "default"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm" {
  bucket = aws_s3_bucket.ssm.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_alias.s3.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "ssm" {
  name              = "/ssm/session"
  retention_in_days = 7
  kms_key_id        = aws_kms_alias.ssm.arn
}

data "aws_iam_policy_document" "ssm_kms_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = ["kms:*"]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
      "logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "ssm" {
  description = "session manager encryption"
  policy      = data.aws_iam_policy_document.ssm_kms_policy.json
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/ssm/session"
  target_key_id = aws_kms_key.ssm.key_id
}
