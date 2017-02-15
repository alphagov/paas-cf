resource "aws_elb" "rds_broker" {
  name                      = "${var.env}-rds-broker"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal                  = true
  security_groups           = ["${aws_security_group.service_brokers.id}"]

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
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}

resource "aws_db_subnet_group" "rds_broker" {
  name        = "rdsbroker-${var.env}"
  description = "Subnet group for RDS broker managed instances"
  subnet_ids  = ["${aws_subnet.aws_backing_services.*.id}"]

  tags {
    Name = "rdsbroker-${var.env}"
  }
}

resource "aws_security_group" "rds_broker_db_clients" {
  name        = "${var.env}-rds-broker-db-clients"
  description = "Group for clients of RDS broker DB instances"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.env}-rds-broker-db-clients"
  }
}

resource "aws_security_group" "rds_broker_dbs" {
  name        = "${var.env}-rds-broker-dbs"
  description = "Group for RDS broker DB instances"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.rds_broker_db_clients.id}",
    ]
  }

  tags {
    Name = "${var.env}-rds-broker-dbs"
  }
}

resource "aws_db_parameter_group" "rds_broker_postgres95" {
  name        = "rdsbroker-postgres95-${var.env}"
  family      = "postgres9.5"
  description = "RDS Broker Postgres 9.5 parameter group"

  parameter {
    apply_method = "pending-reboot"
    name         = "rds.force_ssl"
    value        = "1"
  }
}
