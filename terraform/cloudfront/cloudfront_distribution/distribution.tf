resource "aws_route53_record" "cdn_domain" {
  count = "${length(var.aliases)}"

  zone_id = "${var.system_dns_zone_id}"
  name    = "${element(var.aliases, count.index)}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_cloudfront_distribution.cdn_instance.domain_name}"]
}

resource "aws_cloudfront_distribution" "cdn_instance" {
  origin {
    domain_name = "${var.origin}"
    origin_id   = "${var.origin}"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  aliases         = "${var.aliases}"
  comment         = "${var.comment}"
  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.origin}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 5
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    Environment = "${var.env}"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    iam_certificate_id             = "${var.system_domain_cert_id}"
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
}
