resource "random_pet" "elb_cipher" {
  length = 1

  keepers = {
    default_elb_security_policy = "${var.default_elb_security_policy}"
  }
}

resource "aws_elb" "cf_router_system_domain" {
  name                        = "${var.env}-cf-router-system-domain"
  subnets                     = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout                = "${var.elb_idle_timeout}"
  cross_zone_load_balancing   = "true"
  connection_draining         = true
  connection_draining_timeout = 110

  security_groups = ["${aws_security_group.cf_api_elb.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-router-system-domain"
    interval      = 5
  }

  health_check {
    target              = "HTTP:82/health"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 443
    instance_protocol  = "ssl"
    lb_port            = 443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${data.aws_acm_certificate.system.arn}"
  }
}

resource "aws_lb_ssl_negotiation_policy" "cf_router_system_domain" {
  name          = "paas-${random_pet.elb_cipher.keepers.default_elb_security_policy}-${random_pet.elb_cipher.id}"
  load_balancer = "${aws_elb.cf_router_system_domain.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  }
}

resource "aws_proxy_protocol_policy" "cf_router_system_domain_haproxy" {
  load_balancer  = "${aws_elb.cf_router_system_domain.name}"
  instance_ports = ["443"]
}

resource "aws_elb" "cf_doppler" {
  name                      = "${var.env}-cf-doppler"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"

  security_groups = [
    "${aws_security_group.cf_api_elb.id}",
  ]

  access_logs {
    bucket        = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-doppler"
    interval      = 5
  }

  health_check {
    target              = "SSL:8081"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 8081
    instance_protocol  = "ssl"
    lb_port            = 443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${data.aws_acm_certificate.system.arn}"
  }
}

resource "aws_lb_ssl_negotiation_policy" "cf_doppler" {
  name          = "paas-${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  load_balancer = "${aws_elb.cf_doppler.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  }
}

resource "aws_elb" "cf_router" {
  name                      = "${var.env}-cf-router"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"

  security_groups = ["${aws_security_group.web.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-router"
    interval      = 5
  }

  health_check {
    target              = "HTTP:82/health"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 443
    instance_protocol  = "ssl"
    lb_port            = 443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${aws_acm_certificate_validation.apps.certificate_arn}"
  }

  listener {
    lb_port           = "80"
    lb_protocol       = "http"
    instance_port     = "83"
    instance_protocol = "http"
  }
}

resource "aws_lb_ssl_negotiation_policy" "cf_router" {
  name          = "paas-${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  load_balancer = "${aws_elb.cf_router.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  }
}

resource "aws_proxy_protocol_policy" "http_haproxy" {
  load_balancer  = "${aws_elb.cf_router.name}"
  instance_ports = ["443"]
}

resource "aws_elb" "ssh_proxy" {
  name                      = "${var.env}-ssh-proxy"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"

  security_groups = [
    "${aws_security_group.sshproxy.id}",
  ]

  health_check {
    target              = "TCP:2222"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port     = 2222
    instance_protocol = "tcp"
    lb_port           = 2222
    lb_protocol       = "tcp"
  }
}

resource "aws_lb" "cf_loggregator" {
  name               = "${var.env}-cf-loggregator"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.cf_api_elb.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]
}

resource "aws_lb_target_group" "cf_loggregator_rlp" {
  name     = "${var.env}-cf-loggregator-rlp"
  port     = 8088
  protocol = "HTTPS"
  vpc_id   = "${var.vpc_id}"

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

resource "aws_lb_target_group" "cf_doppler" {
  name     = "${var.env}-cf-doppler"
  port     = 8081
  protocol = "HTTPS"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }

  lifecycle {
    create_before_destroy = true
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

output "cf_doppler_target_group_name" {
  value = "${aws_lb_target_group.cf_doppler.name}"
}

resource "aws_lb" "cf_router_app_domain" {
  name               = "${var.env}-cf-rtr-apps"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.web.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]

  enable_deletion_protection = true

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
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_router_app_domain_http.arn}"
  }
}

resource "aws_lb_listener" "cf_router_app_domain_https" {
  load_balancer_arn = "${aws_lb.cf_router_app_domain.arn}"
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "${var.default_elb_security_policy}"
  certificate_arn = "${aws_acm_certificate.apps.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_router_app_domain_https.arn}"
  }
}

resource "aws_lb_target_group" "cf_router_app_domain_https" {
  name     = "${var.env}-app-tls-tg"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port                = 82
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

  health_check {
    port                = 82
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

  enable_deletion_protection = true

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

  ssl_policy      = "${var.default_elb_security_policy}"
  certificate_arn = "${data.aws_acm_certificate.system.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.cf_router_system_domain_https.arn}"
  }
}

resource "aws_lb_target_group" "cf_router_system_domain_https" {
  name     = "${var.env}-system-tls-tg"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = "${var.vpc_id}"

  health_check {
    port                = 82
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

output "cf_router_app_domain_http_target_group_name" {
  value = "${aws_lb_target_group.cf_router_app_domain_http.name}"
}

output "cf_router_app_domain_https_target_group_name" {
  value = "${aws_lb_target_group.cf_router_app_domain_https.name}"
}
