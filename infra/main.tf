provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "portfolio-v4"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# CloudFront requires ACM certificates to be requested in us-east-1
# regardless of where the distribution or other resources live.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "portfolio-v4"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
