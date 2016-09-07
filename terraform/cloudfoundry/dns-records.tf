resource "aws_route53_record" "cf_cc" {
  zone_id = "${var.system_dns_zone_id}"
  name = "api.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_cc.dns_name}"]
}

resource "aws_route53_record" "cf_uaa" {
  zone_id = "${var.system_dns_zone_id}"
  name = "uaa.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_uaa.dns_name}"]
}

resource "aws_route53_record" "cf_login" {
  zone_id = "${var.system_dns_zone_id}"
  name = "login.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_uaa.dns_name}"]
}

resource "aws_route53_record" "cf_loggregator" {
  zone_id = "${var.system_dns_zone_id}"
  name = "loggregator.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_loggregator.dns_name}"]
}

resource "aws_route53_record" "cf_doppler" {
  zone_id = "${var.system_dns_zone_id}"
  name = "doppler.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_doppler.dns_name}"]
}

resource "aws_route53_record" "cf_ssh_proxy" {
  zone_id = "${var.system_dns_zone_id}"
  name = "ssh.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.ssh_proxy.dns_name}"]
}

resource "aws_route53_record" "apps_wildcard" {
  zone_id = "${var.apps_dns_zone_id}"
  name = "*.${var.apps_dns_zone_name}"
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_router.dns_name}"]
}

resource "aws_route53_record" "metrics" {
  zone_id = "${var.system_dns_zone_id}"
  name = "metrics.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.metrics.dns_name}"]
}

resource "aws_route53_record" "logsearch" {
  zone_id = "${var.system_dns_zone_id}"
  name = "logsearch.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.logsearch_kibana.dns_name}"]
}

resource "aws_route53_record" "rds_broker" {
  zone_id = "${var.system_dns_zone_id}"
  name = "rds-broker.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.rds_broker.dns_name}"]
}

resource "aws_route53_record" "spf" {
  zone_id = "${var.system_dns_zone_id}"
  name = "${var.system_dns_zone_name}."
  type = "TXT"
  ttl = "300"
  records = ["v=spf1 -all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = "${var.system_dns_zone_id}"
  name = "_dmarc.${var.system_dns_zone_name}."
  type = "TXT"
  ttl = "300"
  records = ["v=DMARC1; p=reject; rua=mailto:dmarc-groups-test@digital.cabinet-office.gov.uk,dmarc-rua@dmarc.service.gov.uk;ruf=mailto:dmarc-groups-test@digital.cabinet-office.gov.uk,dmarc-ruf@dmarc.service.gov.uk;fo=1"]
}

