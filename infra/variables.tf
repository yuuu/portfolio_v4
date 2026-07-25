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
  description = "Name of the existing Route53 hosted zone that owns domain_name (may equal domain_name itself if it's a delegated zone)"
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

variable "enable_custom_domain" {
  description = <<-EOT
    Whether to attach domain_name to the CloudFront distribution and create
    its Route53 alias record. Keep false until the resource currently
    holding domain_name (e.g. a legacy Amplify distribution) has released
    it, then flip to true during cutover.
  EOT
  type        = bool
  default     = false
}
