resource "aws_security_group" "web" {
  name = "${var.env}-cf-web"
  description = "Security group for web that allows web traffic from the office"
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
    cidr_blocks = [
      "${split(",", var.web_access_cidrs)}",
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.web_access_cidrs)}",
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  tags {
    Name = "${var.env}-cf-web"
  }
}

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
      "${split(",", var.office_cidrs)}"
    ]
  }

  tags {
    Name = "${var.env}-cf-sshproxy"
  }
}
resource "aws_security_group" "bosh" {
  name = "${var.env}-bosh"
  description = "Bosh security group"
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
    security_groups = [
      "${var.concourse_security_group_id}"
    ]
  }

  ingress {
    from_port = 6868
    to_port   = 6868
    protocol  = "tcp"
    security_groups = [
      "${var.concourse_security_group_id}"
    ]
  }

  ingress {
    from_port = 25555
    to_port   = 25555
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bosh_client.id}",
      "${var.concourse_security_group_id}"
    ]
  }

  ingress {
    from_port = 4222
    to_port   = 4222
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bosh_managed.id}",
    ]
  }

  ingress {
    from_port = 25250
    to_port   = 25250
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bosh_managed.id}",
    ]
  }


  ingress {
    from_port = 25777
    to_port   = 25777
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bosh_managed.id}",
    ]
  }

  tags {
    Name = "${var.env}-bosh"
  }
}

resource "aws_security_group" "bosh_client" {
  name = "${var.env}-bosh-client"
  description = "Default security group for VMs which will interact with bosh"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.env}-bosh-client"
  }
}

resource "aws_security_group" "bosh_managed" {
  name = "${var.env}-bosh-managed"
  description = "Default security group for VMs managed by Bosh"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags {
    Name = "${var.env}-bosh-managed"
  }
}

