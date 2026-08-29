variable "management_account_id" {
  description = "AWS account ID that hosts the EnvControl Lambda."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "target_account_id" {
  description = "AWS account ID containing the EC2 instances."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.target_account_id))
    error_message = "target_account_id must be a 12-digit AWS account ID."
  }
}

variable "management_profile" {
  description = "Optional local AWS CLI profile for the management account."
  type        = string
  default     = null
  nullable    = true
}

variable "target_profile" {
  description = "Optional local AWS CLI profile for the target account."
  type        = string
  default     = null
  nullable    = true
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-northeast-1"
}

variable "tag_key" {
  description = "Tag key used to opt EC2 instances into EnvControl."
  type        = string
  default     = "EnvControl"
}

variable "tag_value" {
  description = "Tag value used to opt EC2 instances into EnvControl."
  type        = string
  default     = "True"
}

variable "lambda_function_name" {
  description = "Lambda function name."
  type        = string
  default     = "EnvControl"
}

variable "enable_schedules" {
  description = "Whether to create the optional EventBridge start/stop schedules."
  type        = bool
  default     = false
}

variable "start_schedule_expression" {
  description = "Optional EventBridge cron for start. Default is 09:00 JST weekdays (00:00 UTC)."
  type        = string
  default     = "cron(0 0 ? * MON-FRI *)"
}

variable "stop_schedule_expression" {
  description = "Optional EventBridge cron for stop. Default is 20:00 JST weekdays (11:00 UTC)."
  type        = string
  default     = "cron(0 11 ? * MON-FRI *)"
}


variable "target_deployment_role_arn" {
  description = "Bootstrap IAM role ARN in the target account that Terraform assumes from GitHub Actions."
  type        = string
}
