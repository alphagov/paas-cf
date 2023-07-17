locals {
  # ... required for when adding a new peer with a vpc you're already peered with but on a different subnet
  # terraform thinks there are multiple vpc peering connections for that same peering vpc but this isn't true in AWS
  # if you try to create a new vpc peering for an existing peer then it's updated
  vpc_to_peer_id = {
    for peer in aws_vpc_peering_connection.vpc_peer : peer.peer_vpc_id => peer.id...
  }
  peer_name_to_details = {
    for peer in var.vpc_peers : peer.peer_name => peer
  }
  // filter peers so that we only include peers with the
  // backing_service_routing variable set to "true"
  backing_service_routing_peers = {
    for peer in var.vpc_peers : peer.peer_name => peer if peer.backing_service_routing == true
  }
}

data "aws_route_tables" "internet" {
  vpc_id = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["${var.env}-cf"]
  }
}

data "aws_route_tables" "aws_backing_services" {
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Name"
    values = ["${var.env}-aws-backing-services"]
  }
}

resource "aws_vpc_peering_connection" "vpc_peer" {
  for_each      = local.peer_name_to_details
  peer_owner_id = each.value.account_id
  peer_vpc_id   = each.value.vpc_id
  vpc_id        = var.vpc_id
}

resource "aws_route" "vpc_peer_route_0" {
  for_each                  = local.peer_name_to_details
  route_table_id            = element(tolist(data.aws_route_tables.internet.ids), 0)
  destination_cidr_block    = each.value.subnet_cidr
  vpc_peering_connection_id = local.vpc_to_peer_id[each.value.vpc_id][0]
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "vpc_peer_route_1" {
  for_each                  = local.peer_name_to_details
  route_table_id            = element(tolist(data.aws_route_tables.internet.ids), 1)
  destination_cidr_block    = each.value.subnet_cidr
  vpc_peering_connection_id = local.vpc_to_peer_id[each.value.vpc_id][0]
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "vpc_peer_route_2" {
  for_each                  = local.peer_name_to_details
  route_table_id            = element(tolist(data.aws_route_tables.internet.ids), 2)
  destination_cidr_block    = each.value.subnet_cidr
  vpc_peering_connection_id = local.vpc_to_peer_id[each.value.vpc_id][0]
  timeouts {
    create = "5m"
  }
}

resource "aws_route" "backing_service_to_vpc_peer" {
  for_each = local.backing_service_routing_peers

  route_table_id         = data.aws_route_tables.aws_backing_services.ids[0]
  destination_cidr_block = each.value.subnet_cidr
  gateway_id             = local.vpc_to_peer_id[each.value.vpc_id][0]
}
