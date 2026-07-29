# State is stored in S3. Terraform 1.10+'s S3 native locking (use_lockfile)
# is used instead of a DynamoDB lock table, so the whole backend lives in a
# single S3 bucket.
#
# The state bucket itself is not managed by this configuration (chicken-and-egg
# problem) and must be created once by hand, e.g.:
#   aws s3api create-bucket --bucket portfolio-v4-terraform-state --region ap-northeast-1 \
#     --create-bucket-configuration LocationConstraint=ap-northeast-1
#   aws s3api put-bucket-versioning --bucket portfolio-v4-terraform-state \
#     --versioning-configuration Status=Enabled
#
# staging/production are separated via Terraform workspaces, which the S3
# backend namespaces automatically under `env:/<workspace>/<key>`:
#   terraform workspace new staging && terraform apply -var-file=environments/staging.tfvars
#   terraform workspace new production && terraform apply -var-file=environments/production.tfvars
terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket       = "portfolio-v4-terraform-state"
    key          = "portfolio-v4/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.56"
    }
  }
}
