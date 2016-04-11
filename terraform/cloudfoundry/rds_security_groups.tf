resource "aws_security_group" "cf_rds_client" {
  name = "${var.env}-cf-rds-client"
  description = "Security group of the CF RDS clients"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.env}-cf-rds-client"
  }
}
