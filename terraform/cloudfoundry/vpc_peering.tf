resource "aws_vpc_peering_connection" "vpc_peer" {
  for_each      = toset(var.peer_vpc_ids)
  peer_owner_id = element(var.peer_account_ids, index(var.peer_vpc_ids, each.value))
  peer_vpc_id   = element(var.peer_vpc_ids, index(var.peer_vpc_ids, each.value))
  vpc_id        = var.vpc_id
}

resource "aws_route" "vpc_peer_route_0" {
  for_each                  = toset(var.peer_vpc_ids)
  route_table_id            = aws_route_table.internet[0].id
  destination_cidr_block    = element(var.peer_cidrs, index(var.peer_vpc_ids, each.value))
  vpc_peering_connection_id = element([for peer in aws_vpc_peering_connection.vpc_peer : peer.id], index(var.peer_vpc_ids, each.value))
}

resource "aws_route" "vpc_peer_route_1" {
  for_each                  = toset(var.peer_vpc_ids)
  route_table_id            = aws_route_table.internet[1].id
  destination_cidr_block    = element(var.peer_cidrs, index(var.peer_vpc_ids, each.value))
  vpc_peering_connection_id = element([for peer in aws_vpc_peering_connection.vpc_peer : peer.id], index(var.peer_vpc_ids, each.value))
}

resource "aws_route" "vpc_peer_route_2" {
  for_each                  = toset(var.peer_vpc_ids)
  route_table_id            = aws_route_table.internet[2].id
  destination_cidr_block    = element(var.peer_cidrs, index(var.peer_vpc_ids, each.value))
  vpc_peering_connection_id = element([for peer in aws_vpc_peering_connection.vpc_peer : peer.id], index(var.peer_vpc_ids, each.value))
}
