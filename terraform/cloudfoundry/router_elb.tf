resource "aws_elb" "router" {
  name = "${var.env}-cf-router-elb"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.web.id}",
    "${aws_security_group.pingdom-probes-0.id}",
    "${aws_security_group.pingdom-probes-1.id}",
    "${aws_security_group.pingdom-probes-2.id}"
  ]

  health_check {
    target = "TCP:443"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 443
    instance_protocol = "ssl"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${var.router_external_cert_arn}"
  }
}
