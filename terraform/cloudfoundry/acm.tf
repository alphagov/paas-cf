# Created in concourse-terraform
data "aws_acm_certificate" "system" {
  domain   = "*.${var.system_dns_zone_name}"
  statuses = ["ISSUED"]
}

resource "aws_acm_certificate" "apps" {
  domain_name               = "*.${var.apps_dns_zone_name}"
  subject_alternative_names = [var.apps_dns_zone_name]
  validation_method         = "DNS"
}

resource "aws_route53_record" "apps_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.apps.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.apps_dns_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "apps" {
  certificate_arn = aws_acm_certificate.apps.arn

  validation_record_fqdns = [
  for record in aws_route53_record.apps_cert_validation : record.fqdn
  ]
}

resource "aws_acm_certificate" "metrics" {
  domain_name               = "*.metrics.${var.system_dns_zone_name}"
  subject_alternative_names = ["metrics.${var.system_dns_zone_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "metrics_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.metrics.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.system_dns_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "metrics" {
  certificate_arn = aws_acm_certificate.metrics.arn

  validation_record_fqdns = [for record in aws_route53_record.metrics_cert_validation : record.fqdn]
}
