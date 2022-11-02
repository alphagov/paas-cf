resource "aws_vpc_endpoint" "secrets_manager" {
  count = length(local.migrations) > 0 ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.secrets_manager_dms_access.id,
  ]

  subnet_ids          = aws_subnet.secrets_manager_vpc_endpoint[*].id
  private_dns_enabled = true

  tags = {
    Build       = "terraform"
    Resource    = "aws_vpc_endpoint"
    Environment = var.env
    Name        = "${var.env}-secrets-manager"
  }
}
