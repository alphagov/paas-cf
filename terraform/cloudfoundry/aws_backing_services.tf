resource "aws_subnet" "aws_backing_services" {
  count             = "${var.zone_count}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${lookup(var.aws_backing_service_cidrs, format("zone%d", count.index))}"
  availability_zone = "${lookup(var.zones, format("zone%d", count.index))}"
  map_public_ip_on_launch = false
  tags {
    Name = "${var.env}-aws-backing-service-${count.index}"
  }
}
