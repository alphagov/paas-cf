resource "aws_route53_record" "system_wildcard" {
  zone_id = "${var.system_dns_zone_id}"
  name = "*.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.router.dns_name}"]
}

resource "aws_route53_record" "cf_cc" {
  zone_id = "${var.system_dns_zone_id}"
  name = "api.${var.system_dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.cf_cc.dns_name}"]
}

resource "aws_route53_record" "sshproxy" {
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
  records = ["${aws_elb.router.dns_name}"]
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

