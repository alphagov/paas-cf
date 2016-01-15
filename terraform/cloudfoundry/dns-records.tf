resource "aws_route53_record" "wildcard" {
  zone_id = "${var.dns_zone_id}"
  name = "*.${var.env}.${var.dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.router.dns_name}"]
}

resource "aws_route53_record" "sshproxy" {
  zone_id = "${var.dns_zone_id}"
  name = "ssh.${var.env}.${var.dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.ssh-proxy-router.dns_name}"]
}
