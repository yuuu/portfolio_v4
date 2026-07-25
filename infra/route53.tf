# The apex zone (e.g. y-uuu.net) is managed outside this configuration, since
# it predates this project and is shared with other subdomains/services.
data "aws_route53_zone" "site" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.site.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

# The actual cutover from the legacy Amplify Hosting distribution to this one
# happens by applying this record during the migration's Phase 2 — until
# then, leave it commented out or targeted out with `-target` so `terraform
# apply` doesn't repoint production traffic prematurely.
resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
