data "archive_file" "env_control" {
  type        = "zip"
  source_file = "${path.module}/lambda/env_control.py"
  output_path = "${path.module}/lambda/env_control.zip"
}

resource "aws_lambda_function" "env_control" {
  provider = aws.management

  function_name = var.lambda_function_name
  description   = "Cross-account start/stop control for EC2 instances tagged EnvControl=True."

  role    = aws_iam_role.env_control_lambda_role.arn
  runtime = "python3.12"
  handler = "env_control.lambda_handler"

  filename         = data.archive_file.env_control.output_path
  source_code_hash = data.archive_file.env_control.output_base64sha256

  timeout     = 60
  memory_size = 128

  environment {
    variables = {
      TARGET_ROLE_ARN = local.target_role_arn
      TARGET_REGION   = var.aws_region
      TAG_KEY         = var.tag_key
      TAG_VALUE       = var.tag_value
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy.lambda_permissions
  ]
}

resource "aws_cloudwatch_log_group" "env_control" {
  provider = aws.management

  name              = "/aws/lambda/${aws_lambda_function.env_control.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}
