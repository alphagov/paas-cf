data "aws_security_groups" "rds_broker_db_clients" {
  filter {
    name   = "tag:Name"
    values = ["${var.env}-rds-broker-db-clients"]
  }
}

resource "aws_security_group" "dms" {
  name        = "${var.env}-dms"
  description = "Allow all outbound traffic from DMS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_security_group"
    Environment = var.env
    Name        = "${var.env}-dms"
  }
}
