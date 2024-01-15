resource "aws_lb_listener_rule" "cf_rds_broker" {
  listener_arn = aws_lb_listener.cf_brokers.arn
  priority     = "111"

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cf_rds_broker.arn
  }

  condition {
    host_header {
      values = ["rds-broker.*"]
    }
  }
}

resource "aws_lb_target_group" "cf_rds_broker" {
  name     = "${var.env}-cf-rds-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_rds_broker_target_group_name" {
  value = aws_lb_target_group.cf_rds_broker.name
}

#S3 Broker

resource "aws_lb_listener_rule" "cf_s3_broker" {
  listener_arn = aws_lb_listener.cf_brokers.arn
  priority     = "112"

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cf_s3_broker.arn
  }

  condition {
    host_header {
      values = ["s3-broker.*"]
    }
  }
}

resource "aws_lb_target_group" "cf_s3_broker" {
  name     = "${var.env}-cf-s3-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_s3_broker_target_group_name" {
  value = aws_lb_target_group.cf_s3_broker.name
}

#SQS Broker

resource "aws_lb_listener_rule" "cf_sqs_broker" {
  listener_arn = aws_lb_listener.cf_brokers.arn
  priority     = "115"

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cf_sqs_broker.arn
  }

  condition {
    host_header {
      values = ["sqs-broker.*"]
    }
  }
}

resource "aws_lb_target_group" "cf_sqs_broker" {
  name     = "${var.env}-cf-sqs-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "sqs_broker_target_group_name" {
  value = aws_lb_target_group.cf_sqs_broker.name
}

# CDN broker

resource "aws_lb_listener_rule" "cf_cdn_broker" {
  listener_arn = aws_lb_listener.cf_brokers.arn
  priority     = "113"

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cf_cdn_broker.arn
  }

  condition {
    host_header {
      values = ["cdn-broker.*"]
    }
  }
}

resource "aws_lb_target_group" "cf_cdn_broker" {
  name     = "${var.env}-cf-cdn-broker"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = 3000
    path                = "/healthcheck/http"
    protocol            = "HTTP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_cdn_broker_target_group_name" {
  value = aws_lb_target_group.cf_cdn_broker.name
}

# Elasticache Broker
resource "aws_lb_listener_rule" "cf_elasticache_broker" {
  listener_arn = aws_lb_listener.cf_brokers.arn
  priority     = "114"

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cf_elasticache_broker.arn
  }

  condition {
    host_header {
      values = ["elasticache-broker.*"]
    }
  }
}

resource "aws_lb_target_group" "cf_elasticache_broker" {
  name     = "${var.env}-cf-elasticache-broker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    port                = 80
    path                = "/healthcheck"
    protocol            = "HTTP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cf_elasticache_broker_target_group_name" {
  value = aws_lb_target_group.cf_elasticache_broker.name
}
