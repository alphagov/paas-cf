resource "aws_vpn_gateway" "default" {
  count = length(local.vpn_data) > 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = {
    Build       = "terraform"
    Resource    = "aws_vpn_gateway"
    Environment = var.env
    Name        = "${var.env}"
  }
}

resource "aws_customer_gateway" "default" {
  for_each = local.aws_customer_gateways

  bgp_asn    = each.value.bgp_asn
  ip_address = each.value.ip_address
  type       = each.value.type

  tags = {
    Build       = "terraform"
    Resource    = "aws_customer_gateway"
    Environment = var.env
    Name        = "${var.env}-${each.key}"
  }
}

resource "aws_vpn_connection" "default" {
  for_each = local.vpn_data

  customer_gateway_id      = aws_customer_gateway.default[each.key].id
  vpn_gateway_id           = local.vpn_gateway_id
  type                     = each.value.aws_vpn_connection.type
  static_routes_only       = true
  tunnel_inside_ip_version = each.value.aws_vpn_connection.tunnel_inside_ip_version
  tunnel1_preshared_key    = var.vpn_key_data[each.key].tunnel1_preshared_key
  tunnel2_preshared_key    = var.vpn_key_data[each.key].tunnel2_preshared_key
  
  tunnel1_dpd_timeout_action           = "clear"
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_dh_group_numbers      = [2]
  tunnel1_phase1_encryption_algorithms = ["AES128"]
  tunnel1_phase2_encryption_algorithms = ["AES128"]
  tunnel1_phase1_lifetime_seconds      = 28800
  tunnel1_phase2_lifetime_seconds      = 3600
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_startup_action               = "add"

  tunnel2_dpd_timeout_action           = "clear"
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_dh_group_numbers      = [2]
  tunnel2_phase1_encryption_algorithms = ["AES128"]
  tunnel2_phase2_encryption_algorithms = ["AES128"]
  tunnel2_phase1_lifetime_seconds      = 28800
  tunnel2_phase2_lifetime_seconds      = 3600
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_startup_action               = "add"

  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled       = true
      log_group_arn     = aws_cloudwatch_log_group.tunnel1[each.key].arn
      log_output_format = "json"
    }
  }

  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled       = true
      log_group_arn     = aws_cloudwatch_log_group.tunnel2[each.key].arn
      log_output_format = "json"
    }
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_vpn_connection"
    Environment = var.env
    Name        = "${var.env}-${each.value.name}"
  }
}

resource "aws_vpn_connection_route" "default" {
  for_each = local.destination_cidr_blocks

  destination_cidr_block = each.value.cidr
  vpn_connection_id      = aws_vpn_connection.default[each.value.vpn_name].id
}
