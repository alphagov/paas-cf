resource "aws_security_group" "vpn_to_rds_broker_dbs" {
  name        = "${var.env}-vpn-to-rds-broker-dbs"
  description = "Allow VPN connection inbound Postgresql traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.vpn_data
    content {
      cidr_blocks = ingress.value.aws_vpn_connection.destination_cidr_blocks
      description = "from VPN to Postgresql"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
    }
  }

  dynamic "egress" {
    for_each = local.vpn_data
    content {
      cidr_blocks = egress.value.aws_vpn_connection.destination_cidr_blocks
      description = "from Postgresql to VPN"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
    }
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_security_group"
    Environment = var.env
    Name        = "${var.env}-vpn-to-rds-broker-dbs"
  }
}

data "aws_network_acls" "default" {
  vpc_id = var.vpc_id

  filter {
    name   = "default"
    values = [true]
  }
}

resource "aws_network_acl_rule" "destination_postgres_rule" {
  for_each = local.destination_cidr_blocks

  network_acl_id = data.aws_network_acls.default.ids[0]
  rule_number    = 40 + index(local.destination_cidrs, each.value)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "destination_dns_rule" {
  for_each = local.destination_cidr_blocks

  network_acl_id = data.aws_network_acls.default.ids[0]
  rule_number    = 60 + index(local.destination_cidrs, each.value)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr
  from_port      = 53
  to_port        = 53
}

resource "aws_network_acl_rule" "deny_rule" {
  for_each = local.destination_cidr_blocks

  network_acl_id = data.aws_network_acls.default.ids[0]
  rule_number    = 80 + index(local.destination_cidrs, each.value)
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = each.value.cidr
}
