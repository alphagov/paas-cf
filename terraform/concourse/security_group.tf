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
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.concourse-elb.id}"]
  }

  ingress {
    from_port   = 6868
    to_port     = 6868
    protocol    = "tcp"
    cidr_blocks = ["${compact(concat(split(",", var.admin_cidrs), list(var.vagrant_cidr)))}"]
  }

  tags {
    Name = "${var.env}-concourse"
  }
}
