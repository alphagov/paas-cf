resource "aws_security_group" "cloud_controller" {
  name        = "${var.env}-cloud-controller"
  description = "Group for VMs acting as part of the Cloud Controller"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.env}-cloud-controller"
  }
}

resource "aws_security_group" "cf_api_elb" {
  name_prefix = "${var.env}-cf-api-elb-"
  description = "Security group for CF API public endpoints"
  vpc_id      = "${var.vpc_id}"

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
      "${compact(var.admin_cidrs)}",
      "${compact(var.api_access_cidrs)}",
      "${var.concourse_elastic_ip}/32",
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-api"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.env}-cf-web-"
  description = "Security group for web that allows HTTP(S) traffic from anywhere"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow for HTTP redirects
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env}-cf-web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sshproxy" {
  name_prefix = "${var.env}-sshproxy-cf-"
  description = "Security group that allows TCP/2222 for cf ssh support"
  vpc_id      = "${var.vpc_id}"

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
      "${compact(var.admin_cidrs)}",
      "${compact(var.api_access_cidrs)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  tags {
    Name = "${var.env}-cf-sshproxy"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "service_brokers" {
  name_prefix = "${var.env}-service-brokers-"
  description = "Group for service brokers that allows CloudController to connect"
  vpc_id      = "${var.vpc_id}"

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

    security_groups = [
      "${aws_security_group.cloud_controller.id}",
    ]
  }

  tags {
    Name = "${var.env}-service-brokers"
  }

  lifecycle {
    create_before_destroy = true
  }
}
