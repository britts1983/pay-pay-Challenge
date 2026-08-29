output "lambda_function_name" {
  description = "EnvControl Lambda function name."
  value       = aws_lambda_function.env_control.function_name
}

output "lambda_role_arn" {
  description = "Management account Lambda execution role ARN."
  value       = aws_iam_role.env_control_lambda_role.arn
}

output "target_role_arn" {
  description = "Target account EnvControl role ARN."
  value       = aws_iam_role.env_control_role.arn
}
