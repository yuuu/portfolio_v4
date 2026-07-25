# portfolio.y-uuu.net is itself a hosted zone delegated from the parent
# y-uuu.net zone (which lives outside this AWS account), not a record inside
# a y-uuu.net zone managed here. It currently holds the legacy Amplify
# Hosting distribution's alias record plus its ACM validation records.
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
# happens by setting enable_custom_domain=true during the migration's cutover
# step, once the Amplify distribution has released domain_name.
resource "aws_route53_record" "site" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_www" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
