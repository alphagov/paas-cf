variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which the endpoint will be used."
}

variable "vpc_endpoint" {
  type        = string
  description = "The service name, in the form com.amazonaws.region.service for AWS services."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The ID of one or more subnets in which to create a network interface for the endpoint."
}

variable "security_group_name" {
  type        = string
  description = "The security group to allow access to the PSN VPC Endpoint."
}

data "aws_security_group" "security_group" {
  name = var.security_group_name
}

resource "aws_vpc_endpoint" "psn_service" {
  vpc_id            = var.vpc_id
  service_name      = var.vpc_endpoint
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.psn_endpoint.id]

  subnet_ids          = var.subnet_ids
  private_dns_enabled = false
}

resource "aws_security_group" "psn_endpoint" {
  name        = "psn-endpoint"
  description = "The PSN VPC Endpoint"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "psn_ingress_from_cells" {
  security_group_id = aws_security_group.psn_endpoint.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 3128
  to_port   = 3128

  source_security_group_id = data.aws_security_group.security_group.id
}

resource "aws_security_group_rule" "cells_egress_to_psn" {
  security_group_id = data.aws_security_group.security_group.id

  type      = "egress"
  protocol  = "tcp"
  from_port = 3128
  to_port   = 3128

  source_security_group_id = aws_security_group.psn_endpoint.id
}

data "aws_network_interface" "psn_interface" {
  for_each = aws_vpc_endpoint.psn_service.network_interface_ids

  id = each.value
}

output "psn_security_group_seed_json" {
  value = templatefile(
    "${path.module}/data/security-group-seed.json.tpl",
    {
      psn_cidrs = [for interface in data.aws_network_interface.psn_interface : interface.private_ip]
    }
  )
}
