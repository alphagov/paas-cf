
resource "aws_security_group" "service_brokers" {
  name = "${var.env}-service-brokers"
  description = "Group for service brokers"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.cloud_controller.id}",
    ]
  }

  tags {
    Name = "${var.env}-service-brokers"
  }
}
