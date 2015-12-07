resource "aws_eip" "concourse" {
  vpc = true
}

resource "aws_route53_record" "concourse" {
  zone_id = "${var.dns_zone_id}"
  name = "${var.env}-concourse.${var.dns_zone_name}."
  type = "A"
  ttl = "60"
  records = ["${aws_eip.concourse.public_ip}"]
}
