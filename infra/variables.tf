variable "aws_region" {
  description = "AWS region for regional resources (S3 bucket, etc.)"
  type        = string
  default     = "ap-northeast-1"
}

variable "domain_name" {
  description = "Fully-qualified domain name the site is served from"
  type        = string
}

variable "route53_zone_name" {
  description = "Name of the existing Route53 hosted zone that owns domain_name (e.g. y-uuu.net)"
  type        = string
}

variable "environment" {
  description = "Deployment environment, used to namespace resource names (e.g. staging, production)"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deploy role, in \"owner/repo\" form"
  type        = string
  default     = "yuuu/portfolio_v4"
}
