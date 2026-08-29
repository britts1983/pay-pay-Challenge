variable "management_account_id" {
  type        = string
  description = "AWS account ID of the management account."
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
