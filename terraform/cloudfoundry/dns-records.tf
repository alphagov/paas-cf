resource "aws_route53_record" "wildcard" {
  zone_id = "${var.dns_zone_id}"
  name = "*.${var.env}.${var.dns_zone_name}."
  type = "CNAME"
  ttl = "60"
  records = ["${aws_elb.router.dns_name}"]
}
