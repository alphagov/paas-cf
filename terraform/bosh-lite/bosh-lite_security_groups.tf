resource "aws_security_group" "bosh_lite_office" {
  name        = "${var.env}-bosh-lite-office-access"
  description = "Bosh-lite security group to access from the office"
  vpc_id      = "${aws_vpc.bosh-lite-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${compact(concat(var.admin_cidrs))}"]
  }

  ingress {
    from_port   = 25555
    to_port     = 25555
    protocol    = "tcp"
    cidr_blocks = ["${compact(concat(var.admin_cidrs))}"]
  }

  tags {
    Name       = "${var.env}-bosh-lite-office-access"
    Created-by = "terraform-bosh-lite"
  }
}
