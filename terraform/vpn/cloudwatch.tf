resource "aws_cloudwatch_log_group" "tunnel1" {
  for_each = local.vpn_data

  name              = "${var.env}-${each.value.name}-tunnel1"
  retention_in_days = 180

  tags = {
    Build       = "terraform"
    Resource    = "aws_cloudwatch_log_group"
    Environment = var.env
    Name        = "${var.env}-${each.value.name}-tunnel1"
  }
}

resource "aws_cloudwatch_log_group" "tunnel2" {
  for_each = local.vpn_data

  name              = "${var.env}-${each.value.name}-tunnel2"
  retention_in_days = 180

  tags = {
    Build       = "terraform"
    Resource    = "aws_cloudwatch_log_group"
    Environment = var.env
    Name        = "${var.env}-${each.value.name}-tunnel2"
  }
}
