resource "aws_shield_protection" "shield_for_app_gorouter_alb" {
  name         = "${var.env}-app-gorouter-shield"
  resource_arn = aws_lb.cf_router_app_domain.arn

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    deploy_env = var.env
  }
}

resource "aws_shield_protection" "shield_for_system_gorouter_alb" {
  name         = "${var.env}-system-gorouter-shield"
  resource_arn = aws_lb.cf_router_system_domain.arn

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    deploy_env = var.env
  }
}

resource "aws_wafv2_ip_set" "self_egress_ips" {
  name = "${var.env}-egress-ips"
  description = "${var.env}s own cloudfoundry egress IPs"
  scope = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [for eip in aws_eip.cf : "${eip.public_ip}/32"]

  tags = {
    deploy_env = var.env
  }
}

resource "aws_wafv2_ip_set" "self_sys_ips" {
  name = "${var.env}-sys-ips"
  description = "${var.env}s own system egress IPs"
  scope = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "${var.concourse_elastic_ip}/32",
  ]

  tags = {
    deploy_env = var.env
  }
}

resource "aws_wafv2_web_acl" "rtr_lbs_acl" {
  name = "${var.env}-rtr-lbs-web-acl"
  description = "Web ACL for requests hitting ${var.env}s gorouter-bound load-balancers"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name = "${var.env}-rtr-lbs-allow-self-sys-ips"
    priority = 10

    action {
      allow {}
      # terminate processing
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.self_sys_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.env}-rtr-lbs-self-sys-ips-allowed"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name = "${var.env}-rtr-lbs-allow-self-egress-ips"
    priority = 20

    action {
      allow {}
      # terminate processing
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.self_egress_ips.arn
          }
        }

        statement {
          and_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.self_egress_ips.arn

                ip_set_forwarded_ip_config {
                  fallback_behavior = "NO_MATCH"
                  header_name = "X-Forwarded-For"
                  position = "LAST"
                }
              }
            }

            statement {
              byte_match_statement {
                field_to_match {
                  single_header {
                    # chosen because we know the gorouter will overwrite it
                    # before delivering to tenant
                    name = "x-cf-instanceid"
                  }
                }
                positional_constraint = "EXACTLY"
                search_string = "x-paas-xff-auth-${var.waf_xff_auth_key}"

                text_transformation {
                  priority = 10
                  type = "COMPRESS_WHITE_SPACE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.env}-rtr-lbs-self-egress-ips-allowed"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name = "${var.env}-rtr-lbs-max-request-rate-direct"
    priority = 30

    action {
      block {
        custom_response {
          response_code = "429"
        }
      }
      # terminate processing, but only when rate limit
      # is hit
    }

    statement {
      rate_based_statement {
        limit = "${var.waf_per_ip_rate_limit_5m}"
        aggregate_key_type = "IP"

        scope_down_statement {
          not_statement {
            statement {
              byte_match_statement {
                field_to_match {
                  single_header {
                    # chosen because we know the gorouter will overwrite it
                    # before delivering to tenant
                    name = "x-cf-instanceid"
                  }
                }
                positional_constraint = "EXACTLY"
                search_string = "x-paas-xff-auth-${var.waf_xff_auth_key}"

                text_transformation {
                  priority = 10
                  type = "COMPRESS_WHITE_SPACE"
                }
              }
            }
          }
        }
      }

    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.env}-rtr-lbs-max-request-rate-direct-blocked"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name = "${var.env}-rtr-lbs-max-request-rate-xff"
    priority = 40

    action {
      block {
        custom_response {
          response_code = "429"
        }
      }
      # terminate processing, but only when rate limit
      # is hit
    }

    statement {
      rate_based_statement {
        limit = "${var.waf_per_ip_rate_limit_5m}"
        aggregate_key_type = "FORWARDED_IP"

        forwarded_ip_config {
          fallback_behavior = "NO_MATCH"
          header_name = "X-Forwarded-For"
        }

        scope_down_statement {
          byte_match_statement {
            field_to_match {
              single_header {
                # chosen because we know the gorouter will overwrite it
                # before delivering to tenant
                name = "x-cf-instanceid"
              }
            }
            positional_constraint = "EXACTLY"
            search_string = "x-paas-xff-auth-${var.waf_xff_auth_key}"

            text_transformation {
              priority = 10
              type = "COMPRESS_WHITE_SPACE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.env}-rtr-lbs-max-request-rate-xff-blocked"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    deploy_env = var.env
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-rtr-lbs"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "rtr_app_lb_acl_assoc" {
  resource_arn = aws_lb.cf_router_app_domain.arn
  web_acl_arn = aws_wafv2_web_acl.rtr_lbs_acl.arn
}

resource "aws_wafv2_web_acl_association" "rtr_system_lb_acl_assoc" {
  resource_arn = aws_lb.cf_router_system_domain.arn
  web_acl_arn = aws_wafv2_web_acl.rtr_lbs_acl.arn
}
