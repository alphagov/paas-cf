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

  /* FIXME: Merge these two ingress block back together once */
  /* https://github.com/hashicorp/terraform/issues/5301 is resolved. */
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.web_access_cidrs)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
    ]
  }

  /* FIXME: Merge these two ingress block back together once */
  /* https://github.com/hashicorp/terraform/issues/5301 is resolved. */
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.web_access_cidrs)}",
      "${var.concourse_elastic_ip}/32",
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${formatlist("%s/32", aws_eip.cf.*.public_ip)}",
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

resource "aws_security_group" "cf_rds_client" {
  name = "${var.env}-cf-rds-client"
  description = "Security group of the CF RDS clients"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.env}-cf-rds-client"
  }
}

resource "aws_security_group" "ingestor_elb" {
  name = "${var.env}-ingestor-cf"
  description = "Security group for web that allows TCP/5514 for logsearch ingestor"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2514
    to_port   = 2514
    protocol  = "tcp"
    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }

  ingress {
    from_port = 5514
    to_port   = 5514
    protocol  = "tcp"
    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }

  tags {
    Name = "${var.env}-logsearch-ingestor"
  }
}

resource "aws_security_group" "elastic_master_elb" {
  name = "${var.env}-elastic-cf"
  description = "Security group for elastic master which allows TCP/9200"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }

  tags {
    Name = "${var.env}-logsearch-elastic"
  }
}

resource "aws_security_group" "grafana_elb" {
  name = "${var.env}-grafana"
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
      "${var.vpc_cidr}"
    ]
  }

  ingress {
    from_port = 3001
    to_port   = 3001
    protocol  = "tcp"
    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }

  tags {
    Name = "${var.env}-grafana_elb"
  }
}


