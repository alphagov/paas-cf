resource "aws_route53_record" "cf_cc" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "api.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_cc.dns_name}"]
}

resource "aws_route53_record" "cf_uaa" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "uaa.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_uaa.dns_name}"]
}

resource "aws_route53_record" "cf_login" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "login.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_uaa.dns_name}"]
}

resource "aws_route53_record" "cf_loggregator" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "loggregator.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_loggregator.dns_name}"]
}

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

resource "aws_route53_record" "apps_wildcard" {
  zone_id = "${var.apps_dns_zone_id}"
  name    = "*.${var.apps_dns_zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.cf_router.dns_name}"]
}

resource "aws_route53_record" "apps_apex" {
  zone_id = "${var.apps_dns_zone_id}"
  name    = "${var.apps_dns_zone_name}."
  type    = "A"

  alias {
    name = "${aws_elb.cf_router.dns_name}."

    # FIXME: Workaround for the issue described in
    # https://github.com/hashicorp/terraform/issues/10007#issuecomment-281417653
    # We would use a hardcoded zone_id rather than the one reported by
    # the ELB terraform resource
    # zone_id                = "${aws_elb.cf_router.zone_id}"
    zone_id = "${lookup(var.elb_zone_ids, var.region)}"

    evaluate_target_health = true
  }
}

resource "aws_route53_record" "metrics" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "metrics.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.metrics.dns_name}"]
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

resource "aws_route53_record" "status" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "status.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "300"
  records = ["h4wt7brwsqr0.stspg-customer.com"]
}
