data "aws_security_groups" "rds_broker_db_clients" {
  filter {
    name   = "tag:Name"
    values = ["${var.env}-rds-broker-db-clients"]
  }
}

resource "aws_security_group" "secrets_manager_dms_access" {
  name        = "${var.env}-secrets-manager-dms"
  description = "Allow HTTPS inbound traffic for security manager vpc endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS for security manager vpc endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [for k, v in var.aws_vpc_endpoint_cidrs_per_zone : v]
  }

  tags = {
    Build       = "terraform"
    Resource    = "aws_security_group"
    Environment = var.env
    Name        = "${var.env}-secrets-manager-dms"
  }
}
