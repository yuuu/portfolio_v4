# NOTE: an AWS account can only have one OIDC provider per URL. If
# https://token.actions.githubusercontent.com is already registered (e.g. by
# another project), import it instead of letting this resource create a
# duplicate:
#   terraform import aws_iam_openid_connect_provider.github_actions <existing-arn>
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # AWS no longer validates this thumbprint for GitHub's OIDC issuer, but the
  # argument is still required.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  github_repository_owner = split("/", var.github_repository)[0]
  github_repository_name  = split("/", var.github_repository)[1]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Belt-and-suspenders repository check (readable, but on its own not
    # accepted by AWS - see the `sub` condition below).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = [var.github_repository]
    }

    # AWS requires the trust policy to scope on `sub` (or `job_workflow_ref`)
    # directly; a condition on `repository` alone is rejected as "not scoped
    # to all". GitHub's `sub` claim now embeds numeric actor/repo IDs
    # (repo:owner@actor_id/repo@repo_id:ref:refs/heads/main) rather than the
    # plain "owner/repo:*" form, hence the wildcards around each ID.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repository_owner}@*/${local.github_repository_name}@*:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "portfolio-v4-github-actions-deploy-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Deliberately scoped to just what build-deploy.yml needs: sync the built
# site to S3 and invalidate the CDN cache. No long-lived access keys involved.
data "aws_iam_policy_document" "github_actions_deploy_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "deploy-permissions"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy_permissions.json
}
