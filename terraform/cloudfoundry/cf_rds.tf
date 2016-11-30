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

resource "aws_db_parameter_group" "cf" {
  name        = "${var.env}-cf"
  family      = "postgres9.4"
  description = "RDS CF Postgres parameter group"

  parameter {
    apply_method = "pending-reboot"
    name         = "max_connections"
    value        = "500"
  }
}

resource "aws_db_instance" "cf" {
  identifier           = "${var.env}-cf"
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "9.4.5"
  instance_class       = "db.t2.micro"
  username             = "dbadmin"
  password             = "${var.secrets_cf_db_master_password}"
  db_subnet_group_name = "${aws_db_subnet_group.cf_rds.name}"
  parameter_group_name = "${aws_db_parameter_group.cf.id}"

  storage_type               = "gp2"
  backup_window              = "02:00-03:00"
  maintenance_window         = "Thu:04:00-Thu:05:00"
  multi_az                   = "${var.cf_db_multi_az}"
  backup_retention_period    = "${var.cf_db_backup_retention_period}"
  final_snapshot_identifier  = "${var.env}-cf-rds-final-snapshot"
  skip_final_snapshot        = "${var.cf_db_skip_final_snapshot}"
  vpc_security_group_ids     = ["${aws_security_group.cf_rds.id}"]
  auto_minor_version_upgrade = false

  tags {
    Name = "${var.env}-cf"
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
