resource "aws_vpc" "bosh-lite-vpc" {
  cidr_block = "${var.bosh_lite_vpc_cidr}"

  tags {
    Name       = "${var.env}-bosh-lite-vpc"
    Created-by = "terraform-bosh-lite"
  }
}
