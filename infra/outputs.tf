output "site_bucket_name" {
  description = "S3 bucket name that GitHub Actions syncs the built site into"
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID, used for cache invalidation after deploys"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution's default domain name"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN for GitHub Actions to assume via OIDC (set as AWS_DEPLOY_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions_deploy.arn
}
