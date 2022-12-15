resource "aws_route_table" "peering" {
  for_each = local.vpc_peering
  vpc_id   = var.vpc_id

  route {
    cidr_block                = each.value.vpc_peering.cidr_block
    vpc_peering_connection_id = each.value.vpc_peering.vpc_peering_connection_id
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_route_table"
    Environment = var.env
    Name        = "${var.env}-dms-peering-${each.key}"
  }
}

resource "aws_route_table_association" "peering_0" {
  for_each = local.vpc_peering

  subnet_id      = aws_subnet.aws_dms_replication_zone_0[each.key].id
  route_table_id = aws_route_table.peering[each.key].id
}



resource "aws_route_table_association" "peering_1" {
  for_each = local.vpc_peering

  subnet_id      = aws_subnet.aws_dms_replication_zone_1[each.key].id
  route_table_id = aws_route_table.peering[each.key].id
}



resource "aws_route_table_association" "peering_2" {
  for_each = local.vpc_peering

  subnet_id      = aws_subnet.aws_dms_replication_zone_2[each.key].id
  route_table_id = aws_route_table.peering[each.key].id
}
