resource "aws_security_group" "logsearch_ingestor_elb" {
  name        = "${var.env}-logsearch-ingestor-elb"
  description = "Security group for web that allows TCP/5514 for logsearch ingestor"
  vpc_id      = "${var.vpc_id}"

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
      "${var.vpc_cidr}",
    ]
  }

  ingress {
    from_port = 5514
    to_port   = 5514
    protocol  = "tcp"

    cidr_blocks = [
      "${var.vpc_cidr}",
    ]
  }

  tags {
    Name = "${var.env}-logsearch-ingestor"
  }
}

resource "aws_security_group" "logsearch_elastic_master_elb" {
  name        = "${var.env}-logsearch-elastic-master-elb"
  description = "Security group for elastic master which allows TCP/9200"
  vpc_id      = "${var.vpc_id}"

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
      "${var.vpc_cidr}",
    ]
  }

  tags {
    Name = "${var.env}-logsearch-elastic-master-elb"
  }
}

resource "aws_security_group" "logsearch_elb" {
  name        = "${var.env}-logsearch"
  description = "Security group for logsearch ELB"
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
      "${compact(split(",", var.admin_cidrs))}",
    ]
  }

  tags {
    Name = "${var.env}-logsearch_elb"
  }
}
