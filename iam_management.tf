data "aws_iam_policy_document" "lambda_trust" {
  statement {
    sid     = "AllowLambdaService"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "env_control_lambda_role" {
  provider = aws.management

  name               = local.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${var.management_account_id}:*"
    ]
  }

  statement {
    sid     = "AllowAssumeEnvControlRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    resources = [
      local.target_role_arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  provider = aws.management

  name   = "EnvControlLambdaPolicy"
  role   = aws_iam_role.env_control_lambda_role.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
