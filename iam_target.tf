data "aws_iam_policy_document" "target_role_trust" {
  statement {
    sid     = "AllowEnvControlLambdaRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${var.management_account_id}:role/${local.lambda_role_name}"
      ]
    }
  }
}

resource "aws_iam_role" "env_control_role" {
  provider = aws.target

  name               = local.target_role_name
  assume_role_policy = data.aws_iam_policy_document.target_role_trust.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "target_ec2_permissions" {
  # DescribeInstances does not support resource-level permissions.
  statement {
    sid       = "AllowDescribeInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  # Start/Stop is restricted to EC2 instances carrying EnvControl=True.
  statement {
    sid    = "AllowStartStopTaggedInstances"
    effect = "Allow"

    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${var.target_account_id}:instance/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.tag_key}"
      values   = [var.tag_value]
    }
  }
}

resource "aws_iam_role_policy" "target_ec2_permissions" {
  provider = aws.target

  name   = "EnvControlEC2Policy"
  role   = aws_iam_role.env_control_role.id
  policy = data.aws_iam_policy_document.target_ec2_permissions.json
}
