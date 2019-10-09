resource "aws_db_subnet_group" "cf_rds" {
  name        = "${var.env}-cf"
  description = "Subnet group for CF RDS"
  subnet_ids  = ["${split(",", var.infra_subnet_ids)}"]

  tags {
    Name = "${var.env}-cf-rds"
  }
}

resource "aws_security_group" "cf_rds" {
  name        = "${var.env}-cf-rds"
  description = "CF RDS security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.cf_rds_client.id}",
      "${var.concourse_security_group_id}",
    ]
  }

  tags {
    Name = "${var.env}-cf-rds"
  }
}

resource "aws_db_parameter_group" "cf_pg_9_5" {
  name        = "${var.env}-pg95-cf"
  family      = "postgres9.5"
  description = "RDS CF Postgres 9.5 parameter group"
}

resource "aws_db_parameter_group" "cf_pg_11" {
  name        = "${var.env}-pg11-cf"
  family      = "postgres11"
  description = "RDS Postgres 11 default parameter group"
}

resource "aws_db_instance" "cf" {
  identifier           = "${var.env}-cf"
  allocated_storage    = 100
  engine               = "postgres"
  engine_version       = "11.1"
  instance_class       = "${var.cf_db_instance_type}"
  username             = "dbadmin"
  password             = "${var.secrets_cf_db_master_password}"
  db_subnet_group_name = "${aws_db_subnet_group.cf_rds.name}"
  parameter_group_name = "${aws_db_parameter_group.cf_pg_11.id}"

  storage_type              = "gp2"
  backup_window             = "02:00-03:00"
  maintenance_window        = "${var.cf_db_maintenance_window}"
  multi_az                  = "${var.cf_db_multi_az}"
  backup_retention_period   = "${var.cf_db_backup_retention_period}"
  final_snapshot_identifier = "${var.env}-cf-rds-final-snapshot"
  skip_final_snapshot       = "${var.cf_db_skip_final_snapshot}"
  vpc_security_group_ids    = ["${aws_security_group.cf_rds.id}"]

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  apply_immediately           = true

  tags {
    Name       = "${var.env}-cf"
    deploy_env = "${var.env}"
  }
}

resource "aws_security_group" "cf_rds_client" {
  name        = "${var.env}-cf-rds-client"
  description = "Security group of the CF RDS clients"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.env}-cf-rds-client"
  }
}
