resource "aws_lb" "prometheus" {
  name               = "${var.env}-prometheus"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.prometheus-lb.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]

  access_logs {
    bucket  = "${aws_s3_bucket.elb_access_log.id}"
    prefix  = "prometheus"
    enabled = true
  }
}

resource "aws_security_group" "prometheus-lb" {
  name_prefix = "${var.env}-prometheus-lb-"
  description = "Prometheus LB security group"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${compact(var.admin_cidrs)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  tags {
    Name = "${var.env}-prometheus-lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "p8s_alertmanager_target_group_z1" {
  value = "${element(aws_lb_target_group.p8s_alertmanager.*.name, 0)}"
}

output "p8s_alertmanager_target_group_z2" {
  value = "${element(aws_lb_target_group.p8s_alertmanager.*.name, 1)}"
}

resource "aws_lb_target_group" "p8s_alertmanager" {
  count    = "${length(var.prometheus_azs)}"
  name     = "${var.env}-p8s-alertmanager-${element(var.prometheus_azs, count.index)}"
  port     = 9093
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "p8s_grafana_target_group_z1" {
  value = "${element(aws_lb_target_group.p8s_grafana.*.name, 0)}"
}

output "p8s_grafana_target_group_z2" {
  value = "${element(aws_lb_target_group.p8s_grafana.*.name, 1)}"
}

resource "aws_lb_target_group" "p8s_grafana" {
  count    = "${length(var.prometheus_azs)}"
  name     = "${var.env}-p8s-grafana-${element(var.prometheus_azs, count.index)}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "p8s_prometheus_target_group_z1" {
  value = "${element(aws_lb_target_group.p8s_prometheus.*.name, 0)}"
}

output "p8s_prometheus_target_group_z2" {
  value = "${element(aws_lb_target_group.p8s_prometheus.*.name, 1)}"
}

resource "aws_lb_target_group" "p8s_prometheus" {
  count    = "${length(var.prometheus_azs)}"
  name     = "${var.env}-p8s-prometheus-${element(var.prometheus_azs, count.index)}"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = "${aws_lb.prometheus.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "${var.default_elb_security_policy}"
  certificate_arn   = "${data.aws_acm_certificate.system.arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hostname not known"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "p8s_alertmanager" {
  count        = "${length(var.prometheus_azs)}"
  listener_arn = "${aws_lb_listener.prometheus.arn}"
  priority     = "${count.index+1}"

  action {
    type             = "forward"
    target_group_arn = "${element(aws_lb_target_group.p8s_alertmanager.*.arn, count.index)}"
  }

  condition {
    field  = "host-header"
    values = ["alertmanager-${count.index+1}.*"]
  }
}

resource "aws_lb_listener_rule" "p8s_grafana" {
  count        = "${length(var.prometheus_azs)}"
  listener_arn = "${aws_lb_listener.prometheus.arn}"
  priority     = "${count.index+3}"

  action {
    type             = "forward"
    target_group_arn = "${element(aws_lb_target_group.p8s_grafana.*.arn, count.index)}"
  }

  condition {
    field  = "host-header"
    values = ["grafana-${count.index+1}.*"]
  }
}

resource "aws_lb_listener_rule" "p8s_prometheus" {
  count        = "${length(var.prometheus_azs)}"
  listener_arn = "${aws_lb_listener.prometheus.arn}"
  priority     = "${count.index+5}"

  action {
    type             = "forward"
    target_group_arn = "${element(aws_lb_target_group.p8s_prometheus.*.arn, count.index)}"
  }

  condition {
    field  = "host-header"
    values = ["prometheus-${count.index+1}.*"]
  }
}

resource "aws_route53_record" "alertmanager" {
  count   = "${length(var.prometheus_azs)}"
  zone_id = "${var.system_dns_zone_id}"
  name    = "alertmanager-${count.index+1}.${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_lb.prometheus.dns_name}"
    zone_id                = "${aws_lb.prometheus.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana" {
  count   = "${length(var.prometheus_azs)}"
  zone_id = "${var.system_dns_zone_id}"
  name    = "grafana-${count.index+1}.${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_lb.prometheus.dns_name}"
    zone_id                = "${aws_lb.prometheus.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "prometheus" {
  count   = "${length(var.prometheus_azs)}"
  zone_id = "${var.system_dns_zone_id}"
  name    = "prometheus-${count.index+1}.${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_lb.prometheus.dns_name}"
    zone_id                = "${aws_lb.prometheus.zone_id}"
    evaluate_target_health = false
  }
}
