data "aws_route_tables" "main" {
  vpc_id = var.vpc_id

  filter {
    name   = "association.main"
    values = [true]
  }
}

resource "aws_route" "default" {
  for_each = local.destination_cidr_blocks

  route_table_id         = data.aws_route_tables.main.ids[0]
  destination_cidr_block = each.value.cidr
  gateway_id             = local.vpn_gateway_id
}
