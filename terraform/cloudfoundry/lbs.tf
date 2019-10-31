resource "aws_lb" "cf_loggregator" {
  name               = "${var.env}-cf-loggregator"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.cf_api_elb.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]

  access_logs {
    bucket  = "${aws_s3_bucket.elb_access_log.id}"
    prefix  = "cf-loggregator"
    enabled = true
  }
}

resource "aws_lb_target_group" "cf_loggregator_rlp" {
  name                 = "${var.env}-cf-loggregator-rlp"
  port                 = 8088
  protocol             = "HTTPS"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 60

  health_check {
    matcher = "200-499"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_loggregator_rlp_target_group_name" {
  value = "${aws_lb_target_group.cf_loggregator_rlp.name}"
}

resource "aws_lb_listener" "cf_loggregator" {
  load_balancer_arn = "${aws_lb.cf_loggregator.arn}"
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

resource "aws_lb_listener_rule" "cf_loggregator_rlp_log_api" {
  listener_arn = "${aws_lb_listener.cf_loggregator.arn}"
  priority     = "111"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_loggregator_rlp.arn}"
  }

  condition {
    field  = "host-header"
    values = ["log-api.*"]
  }
}

resource "aws_lb_listener_rule" "cf_loggregator_rlp_log_stream" {
  listener_arn = "${aws_lb_listener.cf_loggregator.arn}"
  priority     = "112"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_loggregator_rlp.arn}"
  }

  condition {
    field  = "host-header"
    values = ["log-stream.*"]
  }
}

resource "aws_lb_listener_rule" "cf_doppler" {
  listener_arn = "${aws_lb_listener.cf_loggregator.arn}"
  priority     = "113"

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_doppler.arn}"
  }

  condition {
    field  = "host-header"
    values = ["doppler.*"]
  }
}

resource "aws_lb_target_group" "cf_doppler" {
  name                 = "${var.env}-cf-doppler"
  port                 = 8081
  protocol             = "HTTPS"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 60

  health_check {
    matcher = "200-499"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_doppler_target_group_name" {
  value = "${aws_lb_target_group.cf_doppler.name}"
}

resource "aws_lb" "cf_router_app_domain" {
  name               = "${var.env}-cf-rtr-apps"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.web.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout       = 900

  access_logs {
    bucket  = "${aws_s3_bucket.elb_access_log.id}"
    prefix  = "cf-rtr-apps"
    enabled = true
  }
}

resource "aws_lb_listener" "cf_router_app_domain_http" {
  load_balancer_arn = "${aws_lb.cf_router_app_domain.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      path        = "/"
      query       = ""
    }
  }
}

resource "aws_lb_listener" "cf_router_app_domain_https" {
  load_balancer_arn = "${aws_lb.cf_router_app_domain.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "${var.default_elb_security_policy}"
  certificate_arn   = "${aws_acm_certificate.apps.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_router_app_domain_https.arn}"
  }
}

resource "aws_lb_target_group" "cf_router_app_domain_https" {
  name                 = "${var.env}-app-tls-tg"
  port                 = 8443
  protocol             = "HTTPS"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 110
  slow_start           = 45

  health_check {
    port                = 8080
    path                = "/health"
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

resource "aws_lb_target_group" "cf_router_app_domain_http" {
  name     = "${var.env}-app-tcp-tg"
  port     = 83
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  # This needs to be here whilst we deploy BOSH to deregister the instances

  health_check {
    port                = 8080
    path                = "/health"
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

resource "aws_lb" "cf_router_system_domain" {
  name               = "${var.env}-cf-rtr-sys"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.cf_api_elb.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout       = 900

  access_logs {
    bucket  = "${aws_s3_bucket.elb_access_log.id}"
    prefix  = "cf-rtr-sys"
    enabled = true
  }
}

resource "aws_lb_listener" "cf_router_system_domain_https" {
  load_balancer_arn = "${aws_lb.cf_router_system_domain.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "${var.default_elb_security_policy}"
  certificate_arn   = "${data.aws_acm_certificate.system.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_router_system_domain_https.arn}"
  }
}

resource "aws_lb_target_group" "cf_router_system_domain_https" {
  name                 = "${var.env}-system-tls-tg"
  port                 = 8443
  protocol             = "HTTPS"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 110
  slow_start           = 45

  health_check {
    port                = 8080
    path                = "/health"
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

output "cf_router_system_domain_https_target_group_name" {
  value = "${aws_lb_target_group.cf_router_system_domain_https.name}"
}

output "cf_router_app_domain_https_target_group_name" {
  value = "${aws_lb_target_group.cf_router_app_domain_https.name}"
}
