output "cf1_subnet_id" {
  value = "${aws_subnet.cf.0.id}"
}

output "cf2_subnet_id" {
  value = "${aws_subnet.cf.1.id}"
}

output "ssh_elb_name" {
  value = "${aws_elb.ssh-proxy-router.name}"
}

output "cf_root_domain" {
  value = "${var.env}.${var.dns_zone_name}"
}

output "dns_zone_name" {
  value = "${var.dns_zone_name}"
}

output "elb_name" {
  value = "${aws_elb.router.name}"
}

output "web_access_cidrs" {
  value = "${var.web_access_cidrs}"
}
