resource "aws_route53_record" "bosh" {
  zone_id = "${var.system_dns_zone_id}"
  name = "bosh.${var.system_dns_zone_name}"
  type = "A"
  ttl = "60"
  records = ["${lookup(var.microbosh_ips, var.bosh_az)}"]
}
