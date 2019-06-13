resource "aws_elb" "elasticache_broker" {
  name                      = "${var.env}-elasticache-broker"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal                  = true
  security_groups           = ["${aws_security_group.service_brokers.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-broker-elasticache"
    interval      = 5
  }

  health_check {
    target              = "HTTP:80/healthcheck"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.system.arn}"
  }
}

resource "aws_lb_ssl_negotiation_policy" "elasticache_broker" {
  name          = "paas-${random_pet.elb_cipher.keepers.default_elb_security_policy}-${random_pet.elb_cipher.id}"
  load_balancer = "${aws_elb.elasticache_broker.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  }
}

resource "aws_elasticache_subnet_group" "elasticache_broker" {
  name        = "elasticache-broker-${var.env}"
  description = "Subnet group for ElastiCache broker managed instances"
  subnet_ids  = ["${aws_subnet.aws_backing_services.*.id}"]
}

resource "aws_security_group" "elasticache_broker_clients" {
  name        = "${var.env}-elasticache-broker-clients"
  description = "Group for clients of ElastiCache broker instances"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.env}-elasticache-broker-clients"
  }
}

resource "aws_security_group" "elasticache_broker_instances" {
  name        = "${var.env}-elasticache-broker"
  description = "Group for ElastiCache broker instances"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.elasticache_broker_clients.id}",
    ]
  }

  tags {
    Name = "${var.env}-elasticache-broker-instances"
  }
}
