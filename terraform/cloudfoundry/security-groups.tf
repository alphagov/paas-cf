resource "aws_security_group" "cloud_controller" {
  name        = "${var.env}-cloud-controller"
  description = "Group for VMs acting as part of the Cloud Controller"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.env}-cloud-controller"
  }
}

resource "aws_security_group" "cf_api_elb" {
  name        = "${var.env}-cf-api-elb"
  description = "Security group for CF API public endpoints that allows web traffic from whitelisted IPs"
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
      "${compact(var.tenant_cidrs)}",
      "${var.concourse_elastic_ip}/32",
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-api"
  }
}

resource "aws_security_group" "metrics_elb" {
  name        = "${var.env}-metrics"
  description = "Security group for graphite/grafana ELB"
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
    ]
  }

  ingress {
    from_port = 3001
    to_port   = 3001
    protocol  = "tcp"

    cidr_blocks = [
      "${compact(var.admin_cidrs)}",
    ]
  }

  tags {
    Name = "${var.env}-metrics_elb"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.env}-cf-web"
  description = "Security group for web that allows web traffic from the office"
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
      "${compact(var.tenant_cidrs)}",
      "${compact(var.web_access_cidrs)}",
      "${var.concourse_elastic_ip}/32",
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-web"
  }
}

resource "aws_security_group" "sshproxy" {
  name        = "${var.env}-sshproxy-cf"
  description = "Security group for web that allows TCP/2222 for ssh-proxy from the office"
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
      "${compact(var.tenant_cidrs)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  tags {
    Name = "${var.env}-cf-sshproxy"
  }
}

resource "aws_security_group" "service_brokers" {
  name        = "${var.env}-service-brokers"
  description = "Group for service brokers"
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
}
