locals {
  bearer_service_port = 8080
  mtls_service_port = 9090
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
# IAM Roles
################################################################################
resource "aws_iam_role" "paas_secrets_role" {
  name = "${var.env}-paas-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "paas_secrets_instance_profile" {
  name = "${var.env}-paas-secrets"
  role = aws_iam_role.paas_secrets_role.name
}

output "paas_secrets_instance_profile_name" {
  value = aws_iam_instance_profile.paas_secrets_instance_profile.name
}

resource "aws_iam_policy" "paas_secrets_secrets_manager_actions" {
  name = "${var.env}-paas-secrets-can-manage-secrets-manager"
  description = "Allows the PaaS secrets proof of concept to manage AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:*"
        ]
        Condition = {
          StrikeLike = {
            "secretsmanager:Name": "${var.env}/secrets-poc*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "paas_secrets_secrets_manager_actions" {
  policy_arn = aws_iam_policy.paas_secrets_secrets_manager_actions.arn
  role = aws_iam_role.paas_secrets_role.name
}

resource "aws_iam_policy" "paas_secrets_kms_actions" {
  name = "${var.env}-pas-secrets-can-access-kms"
  description = "Allows the PaaS secrets proof of concept to use its assigned KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = [
          aws_kms_key.paas_secrets_kms_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "paas_secrets_kms_actions" {
  policy_arn = aws_iam_policy.paas_secrets_kms_actions.arn
  role = aws_iam_role.paas_secrets_role.name
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
    port = local.bearer_service_port
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
  subnets = split(",", var.infra_subnet_ids)
  idle_timeout = var.elb_idle_timeout
  load_balancer_type = "network"
  internal = true
}

resource "aws_lb_listener" "paas_secrets_mtls" {
  load_balancer_arn = aws_lb.paas_secrets_mtls.arn
  port = local.remote_port
  protocol = "TLS"
  ssl_policy = var.default_elb_security_policy
  certificate_arn = data.aws_acm_certificate.system.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.paas_secrets_mtls.arn
  }
}

resource "aws_lb_target_group" "paas_secrets_mtls" {
  name = "${var.env}-paas-secrets-mtls"
  port = local.mtls_service_port
  protocol = "TLS"
  vpc_id = var.vpc_id

  health_check {
    port = local.mtls_service_port
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
