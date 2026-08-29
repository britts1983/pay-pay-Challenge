locals {
  lambda_role_name = "EnvControlLambdaRole"
  target_role_name = "EnvControlRole"

  target_role_arn = "arn:aws:iam::${var.target_account_id}:role/${local.target_role_name}"

  common_tags = {
    ManagedBy = "Terraform"
    Project   = "EnvControl"
  }
}
