resource "aws_security_group" "metrics_elb" {
  name = "${var.env}-metrics"
  description = "Security group for graphite/grafana ELB"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${compact(split(",", var.admin_cidrs))}"
    ]
  }

  ingress {
    from_port = 3001
    to_port   = 3001
    protocol  = "tcp"
    cidr_blocks = [
      "${compact(split(",", var.admin_cidrs))}"
    ]
  }

  tags {
    Name = "${var.env}-metrics_elb"
  }
}
