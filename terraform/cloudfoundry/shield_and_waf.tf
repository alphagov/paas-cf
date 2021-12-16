resource "aws_shield_protection" "shield_for_app_gorouter_alb" {
  name         = "${var.env}-app-gorouter-shield"
  resource_arn = aws_lb.cf_router_app_domain.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_shield_protection" "shield_for_system_gorouter_alb" {
  name         = "${var.env}-system-gorouter-shield"
  resource_arn = aws_lb.cf_router_system_domain.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_wafregional_ipset" "notify_tester_ipset" {
  name = "${var.env}-waf-notify-tester-ipset"

  ip_set_descriptor {
    type  = "IPV4"
    value = "54.170.157.122/32"
  }
}

resource "aws_wafregional_rule" "notify_tester_ip_rule" {
  name        = "${var.env}-waf-notify-tester-ip"
  metric_name = "${replace(var.env, "-", "")}WafNotifyTesterIp"

  predicate {
    data_id = aws_wafregional_ipset.notify_tester_ipset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_wafregional_rate_based_rule" "wafregional_max_request_rate_rule" {
  name        = "${var.env}-waf-max-request-rate"
  metric_name = "${replace(var.env, "-", "")}WafMaxRequestRate"

  rate_key   = "IP"
  rate_limit = "600000"
}

resource "aws_wafregional_web_acl" "wafregional_web_acl" {
  name        = "${var.env}-waf-web-acl"
  metric_name = "${replace(var.env, "-", "")}WafWebACL"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "ALLOW"
    }

    priority = 0
    rule_id  = aws_wafregional_rule.notify_tester_ip_rule.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = aws_wafregional_rate_based_rule.wafregional_max_request_rate_rule.id
    type     = "RATE_BASED"
  }
}

resource "aws_wafregional_web_acl_association" "wafregional_acl_app_alb_association" {
  resource_arn = aws_lb.cf_router_app_domain.arn
  web_acl_id   = aws_wafregional_web_acl.wafregional_web_acl.id
}

resource "aws_wafregional_web_acl_association" "wafregional_acl_system_alb_association" {
  resource_arn = aws_lb.cf_router_system_domain.arn
  web_acl_id   = aws_wafregional_web_acl.wafregional_web_acl.id
}

