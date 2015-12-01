resource "aws_security_group" "office-access" {
  vpc_id      = "${aws_vpc.myvpc.id}"
  name        = "${var.env}-office-access"
  description = "Allow access from office"

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

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}"]
  }

  tags {
    Name = "${var.env}-office-access"
  }
}

