resource "aws_security_group" "concourse" {
  name = "${var.env}-concourse"
  description = "Concourse security group"
  vpc_id = "${var.vpc_id}"

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

  ingress {
    from_port = 6868
    to_port   = 6868
    protocol  = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}"]
  }

  tags {
    Name = "${var.env}-concourse-rds"
  }
}
