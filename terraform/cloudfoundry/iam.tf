resource "aws_iam_policy" "restrict_to_local_ips" {
  policy = templatefile("${path.module}/policies/restrict_to_local_ips.json.tpl", {
    nat_gateway_public_ips = jsonencode(aws_nat_gateway.cf.*.public_ip)
  })
  name        = "${var.env}RestrictToLocalIps"
  description = "Restricts access to only be permitted from the egress IPs for the local VPC"
}
