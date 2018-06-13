resource "aws_route53_record" "cf_doppler" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "doppler.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_doppler.dns_name}"]
}

resource "aws_route53_record" "cf_ssh_proxy" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "ssh.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.ssh_proxy.dns_name}"]
}

resource "aws_route53_record" "system_wildcard" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "*.${var.system_dns_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_router_system_domain.dns_name}"]
}

resource "aws_route53_record" "apps_wildcard" {
  zone_id = "${var.apps_dns_zone_id}"
  name    = "*.${var.apps_dns_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_router.dns_name}"]
}

resource "aws_route53_record" "system_apex" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_elb.cf_router_system_domain.dns_name}"
    zone_id                = "${aws_elb.cf_router_system_domain.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "apps_apex" {
  zone_id = "${var.apps_dns_zone_id}"
  name    = "${var.apps_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_elb.cf_router.dns_name}"
    zone_id                = "${aws_elb.cf_router.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "logsearch" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "logsearch.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.logsearch_kibana.dns_name}"]
}

resource "aws_route53_record" "logsearch_ingestor" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "logsearch-ingestor.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.logsearch_ingestor.dns_name}"]
}

resource "aws_route53_record" "rds_broker" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "rds-broker.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.rds_broker.dns_name}"]
}

resource "aws_route53_record" "cdn_broker" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "cdn-broker.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cdn_broker.dns_name}"]
}

resource "aws_route53_record" "elasticache_broker" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "elasticache-broker.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.elasticache_broker.dns_name}"]
}

resource "aws_route53_record" "status" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "status.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "300"
  records = ["h4wt7brwsqr0.stspg-customer.com"]
}
