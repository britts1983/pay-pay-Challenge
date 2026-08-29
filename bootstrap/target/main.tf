data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "target_deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.management_account_id}:role/TerraformDeploymentRole"
      ]
    }
  }
}

resource "aws_iam_role" "target_deployment" {
  name               = "TerraformTargetDeploymentRole"
  assume_role_policy = data.aws_iam_policy_document.target_deploy_trust.json
}

data "aws_iam_policy_document" "target_deployment" {
  statement {
    sid    = "ManageEnvControlTargetIAM"
    effect = "Allow"
    actions = [
                "iam:*",
                "ec2:*",
                "ssm:GetParameter"
             ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "target_deployment" {
  name   = "TerraformTargetDeploymentPolicy"
  role   = aws_iam_role.target_deployment.id
  policy = data.aws_iam_policy_document.target_deployment.json
}

output "target_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "target_deployment_role_arn" {
  value = aws_iam_role.target_deployment.arn
}
