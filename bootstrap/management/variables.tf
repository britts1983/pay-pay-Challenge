variable "github_org" {
  type        = string
  description = "GitHub organization or username."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name."
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform remote state."
}
