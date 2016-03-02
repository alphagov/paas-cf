resource "aws_subnet" "cf" {
  count             = "${var.zone_count}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${lookup(var.cf_cidrs, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  map_public_ip_on_launch = false
  tags {
    Name = "${var.env}-cf-subnet-${count.index}"
  }
}
