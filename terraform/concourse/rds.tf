provider "aws" {
  region = "${var.region}"
}

resource "aws_db_subnet_group" "concourse_rds" {
  name = "${var.env}-concourse-rds-subnet"
  description = "Subnet group for Concourse RDS"
  subnet_ids = [
    "${var.subnet0_id}",
    "${var.subnet1_id}",
    "${var.subnet2_id}"
  ]
}

resource "aws_security_group" "concourse_rds" {
  name = "${var.env}-concourse-rds"
  description = "Concourse RDS security group"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.concourse.id}",
    ]
  }

  tags {
    Name = "${var.env}-concourse-rds"
  }
}

resource "aws_db_instance" "concourse" {
  identifier = "${var.env}-concourse"
  allocated_storage = 10
  engine = "postgres"
  engine_version = "9.4.5"
  instance_class = "db.t2.micro"
  multi_az = true
  name = "concourse"
  username = "dbadmin"
  password = "${var.concourse_db_password}"
  db_subnet_group_name = "${aws_db_subnet_group.concourse_rds.name}"
  parameter_group_name = "default.postgres9.4"
  vpc_security_group_ids = ["${aws_security_group.concourse_rds.id}"]
}
