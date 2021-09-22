locals {
  bearer_service_port = 8080
  mtls_service_port = 9090
  healthcheck_port = 8080
  remote_port = 443
}
################################################################################
# KMS keys
################################################################################
resource "aws_kms_key" "paas_secrets_kms_key" {
  description = "Key used by PaaS Secrets POC when working with AWS Secrets Manager"
}

output "paas_secrets_kms_key_id" {
  value = aws_kms_key.paas_secrets_kms_key.key_id
}

################################################################################
# ALB (bearer auth)
################################################################################
resource "aws_lb" "paas_secrets_bearer" {
  #ALB
  name = "${var.env}-paas-secrets-bearer"
  subnets = split(",", var.infra_subnet_ids)
  idle_timeout = var.elb_idle_timeout
  load_balancer_type = "application"
  internal = false
  security_groups = [
    aws_security_group.paas_secrets.id]

  access_logs {
    bucket = aws_s3_bucket.elb_access_log.id
    prefix = "paas-secrets-bearer"
    enabled = true
  }
}

resource "aws_lb_listener" "paas_secrets_bearer" {
  load_balancer_arn = aws_lb.paas_secrets_bearer.arn
  port = local.remote_port
  protocol = "HTTPS"
  ssl_policy = var.default_elb_security_policy
  certificate_arn = data.aws_acm_certificate.system.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.paas_secrets_bearer.arn
  }
}


resource "aws_lb_target_group" "paas_secrets_bearer" {
  name = "${var.env}-paas-secrets-bearer"
  port = local.bearer_service_port
  protocol = "HTTPS"
  vpc_id = var.vpc_id

  health_check {
    port = local.healthcheck_port
    path = "/healthcheck"
    protocol = "HTTPS"
    interval = var.health_check_interval
    timeout = var.health_check_timeout
    healthy_threshold = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
    matcher = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "paas_secrets_bearer_target_group_name" {
  value = aws_lb_target_group.paas_secrets_bearer.name
}
################################################################################
# NLB (mtls auth)
################################################################################
resource "aws_lb" "paas_secrets_mtls" {
  #NLB
  name = "${var.env}-paas-secrets-mtls"
  subnets = aws_subnet.cell.*.id
  idle_timeout = var.elb_idle_timeout
  load_balancer_type = "network"
  internal = true
}

resource "aws_lb_listener" "paas_secrets_mtls" {
  load_balancer_arn = aws_lb.paas_secrets_mtls.arn
  port = local.remote_port
  protocol = "TCP" # To perform mTLS, we need the listener to act only on TCP, not TLS

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.paas_secrets_mtls.arn
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_lb_target_group" "paas_secrets_mtls" {
  name = "${var.env}-paas-secrets-mtls"
  port = local.mtls_service_port
  protocol = "TLS"
  vpc_id = var.vpc_id

  health_check {
    port = local.healthcheck_port
    path = "/healthcheck"
    protocol = "HTTPS"
    interval = 10
    healthy_threshold = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "paas_secrets_mtls_target_group_name" {
  value = aws_lb_target_group.paas_secrets_mtls.name
}

################################################################################
# DNS
################################################################################
resource "aws_route53_record" "bearer_auth_dns_record" {
  name = "secrets.${var.system_dns_zone_name}"
  type = "CNAME"
  zone_id = var.system_dns_zone_id
  ttl = 300
  
  records = [
    aws_lb.paas_secrets_bearer.dns_name
  ]
}

resource "aws_route53_record" "mtls_dns_record" {
  name = "apps.secrets.${var.system_dns_zone_name}"
  type = "CNAME"
  zone_id = var.system_dns_zone_id
  ttl = 300

  records = [
    aws_lb.paas_secrets_mtls.dns_name
  ]
}
