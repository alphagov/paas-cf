
resource "aws_db_subnet_group" "rds_broker" {
  name = "rdsbroker-${var.env}"
  description = "Subnet group for RDS broker managed instances"
  subnet_ids = [ "${aws_subnet.aws_backing_services.*.id}" ]

  tags {
      Name = "rdsbroker-${var.env}"
  }
}

resource "aws_security_group" "rds_broker_db_clients" {
  name = "${var.env}-rds-broker-db-clients"
  description = "Group for clients of RDS broker DB instances"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.env}-rds-broker-db-clients"
  }
}

resource "aws_security_group" "rds_broker_dbs" {
  name = "${var.env}-rds-broker-dbs"
  description = "Group for RDS broker DB instances"
  vpc_id = "${var.vpc_id}"

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
