data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # Verify the current GitHub OIDC thumbprint before production use.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repository}:*",
        "repo:${var.github_org}@*/${var.github_repository}@*:*"
      ]
    }
  }
}

resource "aws_iam_role" "terraform_deployment" {
  name               = "TerraformDeploymentRole"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

data "aws_iam_policy_document" "terraform_deployment" {
  statement {
    sid    = "ManageEnvControlManagementResources"
    effect = "Allow"

    actions = [
      "iam:*",
      "lambda:*",
      "logs:*",
      "events:*",
      "sts:AssumeRole"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "TerraformState"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "terraform_deployment" {
  name   = "TerraformDeploymentPolicy"
  role   = aws_iam_role.terraform_deployment.id
  policy = data.aws_iam_policy_document.terraform_deployment.json
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "management_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "management_deployment_role_arn" {
  value = aws_iam_role.terraform_deployment.arn
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}
