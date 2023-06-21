resource "aws_route_table" "aws_backing_services" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.env}-aws-backing-services"
  }

  # the vpc-peering may add entries
}

resource "aws_route_table_association" "aws_backing_services" {
  count          = length(var.aws_backing_service_cidrs)
  subnet_id      = aws_subnet.aws_backing_services[count.index].id
  route_table_id = aws_route_table.aws_backing_services.id
}
