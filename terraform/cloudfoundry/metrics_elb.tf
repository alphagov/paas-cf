resource "aws_iam_server_certificate" "metrics" {
  name_prefix = "${var.env}-metrics-"
  certificate_body = "${file("generated-certificates/metrics.crt")}"
  private_key = "${file("generated-certificates/metrics.key")}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "metrics" {
  name = "${var.env}-metrics"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.metrics_elb.id}",
  ]

  health_check {
    target = "TCP:3000"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 3000
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${aws_iam_server_certificate.metrics.arn}"
  }

  listener {
    instance_port = 3001
    instance_protocol = "tcp"
    lb_port = 3001
    lb_protocol = "ssl"
    ssl_certificate_id = "${aws_iam_server_certificate.metrics.arn}"
  }
}
