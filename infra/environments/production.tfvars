environment = "production"
domain_name = "portfolio.y-uuu.net"
# portfolio.y-uuu.net is itself a delegated hosted zone (not a subdomain
# record inside a y-uuu.net zone) - see infra/route53.tf.
route53_zone_name    = "portfolio.y-uuu.net"
enable_custom_domain = true
