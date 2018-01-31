data "aws_acm_certificate" "system" {
  domain   = "*.${var.system_dns_zone_name}"
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "apps" {
  domain   = "*.${var.apps_dns_zone_name}"
  statuses = ["ISSUED"]
}
