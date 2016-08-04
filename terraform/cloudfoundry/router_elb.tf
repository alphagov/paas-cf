resource "aws_elb" "cf_router" {
  name = "${var.env}-cf-router"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.web.id}",
    "${aws_security_group.pingdom-probes-0.id}",
    "${aws_security_group.pingdom-probes-1.id}",
    "${aws_security_group.pingdom-probes-2.id}"
  ]
  access_logs {
    bucket = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-router"
    interval = 5
  }

  health_check {
    target = "HTTP:82/"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 81
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${var.apps_domain_cert_arn}"
  }
}

resource "aws_proxy_protocol_policy" "http_haproxy" {
  load_balancer = "${aws_elb.cf_router.name}"
  instance_ports = ["81"]
}
