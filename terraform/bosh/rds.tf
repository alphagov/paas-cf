resource "aws_db_subnet_group" "bosh_rds" {
  name = "${var.env}-bosh"
  description = "Subnet group for BOSH RDS"
  subnet_ids = [ "${split(",", var.infra_subnet_ids)}"  ]

  tags {
      Name = "${var.env}-bosh-rds"
  }
}

resource "aws_security_group" "bosh_rds" {
  name = "${var.env}-bosh-rds"
  description = "BOSH RDS security group"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bosh.id}",
      "${var.concourse_security_group_id}",
    ]
  }

  tags {
    Name = "${var.env}-bosh-rds"
  }
}

resource "aws_db_parameter_group" "default" {
    name = "${var.env}-bosh"
    family = "postgres9.4"
    description = "RDS Postgres default parameter group"
}

resource "aws_db_instance" "bosh" {
  identifier = "${var.env}-bosh"
  name = "bosh"
  allocated_storage = 5
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "9.4.5"
  instance_class = "db.t2.medium"
  username = "dbadmin"
  password = "${var.secrets_bosh_postgres_password}"
  db_subnet_group_name = "${aws_db_subnet_group.bosh_rds.name}"
  parameter_group_name = "${aws_db_parameter_group.default.id}"
  backup_window = "01:00-02:00"
  maintenance_window = "Thu:03:00-Thu:04:00"
  multi_az = "${var.bosh_db_multi_az}"
  backup_retention_period = "${var.bosh_db_backup_retention_period}"
  final_snapshot_identifier = "${var.env}-bosh-rds-final-snapshot"
  skip_final_snapshot = "${var.bosh_db_skip_final_snapshot}"

  vpc_security_group_ids = ["${aws_security_group.bosh_rds.id}"]

  tags {
      Name = "${var.env}-bosh"
  }
}


