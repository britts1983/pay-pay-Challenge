provider "aws" {
  alias  = "management"
  region = var.aws_region

  allowed_account_ids = [
    var.management_account_id
  ]
}

provider "aws" {
  alias  = "target"
  region = var.aws_region

  assume_role {
    role_arn     = var.target_deployment_role_arn
    session_name = "TerraformGitHubActions"
  }

  allowed_account_ids = [
    var.target_account_id
  ]
}
