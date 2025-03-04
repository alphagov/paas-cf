resource "aws_elb" "cdn_broker" {
  name                      = "${var.env}-cdn-broker"
  subnets                   = split(",", var.infra_subnet_ids)
  idle_timeout              = var.elb_idle_timeout
  cross_zone_load_balancing = "true"
  internal                  = true
  security_groups           = [aws_security_group.service_brokers.id]

  access_logs {
    bucket        = aws_s3_bucket.elb_access_log.id
    bucket_prefix = "cf-broker-cdn"
    interval      = 5
  }

  health_check {
    target              = "HTTPS:443/healthcheck/https"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy
    unhealthy_threshold = var.health_check_unhealthy
  }

  listener {
    instance_port      = 443
    instance_protocol  = "https"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = data.aws_acm_certificate.system.arn
  }
}

resource "aws_lb_ssl_negotiation_policy" "cdn_broker" {
  name          = "paas-${random_pet.elb_cipher.keepers.default_classic_load_balancer_security_policy}-${random_pet.elb_cipher.id}"
  load_balancer = aws_elb.cdn_broker.id
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = random_pet.elb_cipher.keepers.default_classic_load_balancer_security_policy
  }
}

resource "aws_db_subnet_group" "cdn_rds" {
  name        = "${var.env}-cdn"
  description = "Subnet group for CF CDN"
  subnet_ids  = split(",", var.infra_subnet_ids)

  tags = {
    Name = "${var.env}-cdn"
  }
}

resource "aws_security_group" "cdn_rds" {
  name        = "${var.env}-cdn"
  description = "CF CDN security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    security_groups = [
      aws_security_group.cdn_rds_client.id,
      var.concourse_security_group_id,
    ]
  }

  tags = {
    Name = "${var.env}-cdn"
  }
}

resource "aws_db_parameter_group" "cdn_pg_13" {
  name        = "${var.env}-pg13-cdn"
  family      = "postgres13"
  description = "CDN Postgres 13 parameter group"
}

resource "aws_db_instance" "cdn" {
  identifier           = "${var.env}-cdn"
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = "db.t3.small"
  db_name              = "cdn"
  username             = "dbadmin"
  password             = var.secrets_cdn_db_master_password
  db_subnet_group_name = aws_db_subnet_group.cdn_rds.name
  parameter_group_name = aws_db_parameter_group.cdn_pg_13.id

  allow_major_version_upgrade = true
  apply_immediately           = true

  storage_type               = "gp2"
  backup_window              = "02:00-03:00"
  maintenance_window         = var.cdn_db_maintenance_window
  multi_az                   = var.cdn_db_multi_az
  backup_retention_period    = var.cdn_db_backup_retention_period
  final_snapshot_identifier  = "${var.env}-cf-cdn-final-snapshot"
  skip_final_snapshot        = var.cf_db_skip_final_snapshot
  vpc_security_group_ids     = [aws_security_group.cdn_rds.id]
  auto_minor_version_upgrade = true

  tags = {
    Name       = "${var.env}-cdn"
    deploy_env = var.env
  }
}

resource "aws_security_group" "cdn_rds_client" {
  name        = "${var.env}-cdn-rds-client"
  description = "Security group of the CDN clients"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.env}-cdn-rds-client"
  }
}
