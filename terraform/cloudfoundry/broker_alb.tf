resource "aws_lb" "cf_brokers" {
  name               = "${var.env}-cf-brokers"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.service_brokers.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]

  access_logs {
    bucket  = "${aws_s3_bucket.elb_access_log.id}"
    prefix  = "cf-brokers"
    enabled = true
  }
}

resource "aws_lb_listener" "cf_brokers" {
  load_balancer_arn = "${aws_lb.cf_brokers.arn}"
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

#RDS Broker
resource "aws_lb_listener_rule" "cf_rds_broker" {
  listener_arn = "${aws_lb_listener.cf_brokers.arn}"
  priority     = "111"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_rds_broker.arn}"
  }

  condition {
    field  = "host-header"
    values = ["rds-broker.*"]
  }
}

resource "aws_lb_target_group" "cf_rds_broker" {
  name     = "${var.env}-cf-rds-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_rds_broker_target_group_name" {
  value = "${aws_lb_target_group.cf_rds_broker.name}"
}

#S3 Broker

resource "aws_lb_listener_rule" "cf_s3_broker" {
  listener_arn = "${aws_lb_listener.cf_brokers.arn}"
  priority     = "112"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_s3_broker.arn}"
  }

  condition {
    field  = "host-header"
    values = ["s3-broker.*"]
  }
}

resource "aws_lb_target_group" "cf_s3_broker" {
  name     = "${var.env}-cf-s3-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_s3_broker_target_group_name" {
  value = "${aws_lb_target_group.cf_s3_broker.name}"
}

# CDN broker

resource "aws_lb_listener_rule" "cf_cdn_broker" {
  listener_arn = "${aws_lb_listener.cf_brokers.arn}"
  priority     = "113"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_cdn_broker.arn}"
  }

  condition {
    field  = "host-header"
    values = ["cdn-broker.*"]
  }
}

resource "aws_lb_target_group" "cf_cdn_broker" {
  name     = "${var.env}-cf-cdn-broker"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port                = 3000
    path                = "/healthcheck/http"
    protocol            = "HTTP"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_cdn_broker_target_group_name" {
  value = "${aws_lb_target_group.cf_cdn_broker.name}"
}

# Elasticache Broker
resource "aws_lb_listener_rule" "cf_elasticache_broker" {
  listener_arn = "${aws_lb_listener.cf_brokers.arn}"
  priority     = "114"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_elasticache_broker.arn}"
  }

  condition {
    field  = "host-header"
    values = ["elasticache-broker.*"]
  }
}

resource "aws_lb_target_group" "cf_elasticache_broker" {
  name     = "${var.env}-cf-elasticache-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_elasticache_broker_target_group_name" {
  value = "${aws_lb_target_group.cf_elasticache_broker.name}"
}
