provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "${var.vpc_cidr}"
  tags {
    Name = "${var.env}-cf"
  }
}

