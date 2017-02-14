resource "aws_elb" "logsearch_ingestor" {
  name                      = "${var.env}-logsearch-ingestor"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal                  = "true"

  security_groups = [
    "${aws_security_group.logsearch_ingestor_elb_ssl.id}",
  ]

  health_check {
    target              = "TCP:5514"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 5514
    instance_protocol  = "tcp"
    lb_port            = 6514
    lb_protocol        = "ssl"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}

resource "aws_elb" "logsearch_es_master" {
  name                      = "${var.env}-logsearch-es-master"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal                  = "true"

  security_groups = [
    "${aws_security_group.logsearch_elastic_master_elb.id}",
  ]

  health_check {
    target              = "TCP:9200"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port     = 9200
    instance_protocol = "tcp"
    lb_port           = 9200
    lb_protocol       = "tcp"
  }
}

resource "aws_elb" "logsearch_kibana" {
  name                      = "${var.env}-logsearch-kibana"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"

  security_groups = [
    "${aws_security_group.logsearch_elb.id}",
  ]

  health_check {
    target              = "TCP:5602"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 5602
    instance_protocol  = "tcp"
    lb_port            = 443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}

resource "aws_lb_ssl_negotiation_policy" "logsearch_kibana" {
  name          = "paas-${var.default_elb_security_policy}"
  load_balancer = "${aws_elb.logsearch_kibana.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${var.default_elb_security_policy}"
  }
}

resource "aws_security_group" "logsearch_ingestor_elb_ssl" {
  name        = "${var.env}-logsearch-ingestor-elb-ssl"
  description = "Security group for web that allows TCP/6514 for logsearch ingestor"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 6514
    to_port   = 6514
    protocol  = "tcp"

    cidr_blocks = [
      "${var.vpc_cidr}",
    ]
  }

  tags {
    Name = "${var.env}-logsearch-ingestor-ssl"
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
      "${compact(var.admin_cidrs)}",
    ]
  }

  tags {
    Name = "${var.env}-logsearch_elb"
  }
}
