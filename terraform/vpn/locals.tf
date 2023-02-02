locals {
  vpn_data = {
    for index, vpn in var.vpn_data : vpn.name => vpn
  }
  aws_customer_gateways = {
    for index, vpn in var.vpn_data : vpn.name => vpn.aws_customer_gateway
  }
  destination_cidr_blocks = merge([
    for vpn_name, vpn in local.vpn_data : {
      for cidr in vpn.aws_vpn_connection.destination_cidr_blocks : "${vpn_name}-${cidr}" => { "cidr" = cidr, "vpn_name" = vpn_name }
    }
  ]...)
  destination_cidrs = [for k, v in local.destination_cidr_blocks : v]
  vpn_gateway_id = one(aws_vpn_gateway.default[*].id)
}
