resource "aws_security_group" "bastion" {
  name = "${var.env}-bastion"
  description = "Security group for bastion that allows NAT traffic and SSH connections from the office and jenkins"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}"]
  }

  tags {
    Name = "${var.env}-bastion"
  }
}
