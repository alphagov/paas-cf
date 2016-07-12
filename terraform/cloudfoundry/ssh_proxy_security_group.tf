resource "aws_security_group" "sshproxy" {
  name = "${var.env}-sshproxy-cf"
  description = "Security group for web that allows TCP/2222 for ssh-proxy from the office"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2222
    to_port   = 2222
    protocol  = "tcp"
    cidr_blocks = [
      "${compact(split(",", var.admin_cidrs))}",
      "${compact(split(",", var.tenant_cidrs))}",
      "${var.concourse_elastic_ip}/32"
    ]
  }

  tags {
    Name = "${var.env}-cf-sshproxy"
  }
}
