resource "aws_db_parameter_group" "postgres12" {
  name   = "${var.env}-postgres12-logical-replication"
  family = "postgres12"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_db_parameter_group"
    Environment = var.env
    Name        = "${var.env}-postgres12-logical-replication"
  }
}
resource "aws_db_parameter_group" "postgres13" {
  name   = "${var.env}-postgres13-logical-replication"
  family = "postgres13"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_db_parameter_group"
    Environment = var.env
    Name        = "${var.env}-postgres13-logical-replication"
  }
}
