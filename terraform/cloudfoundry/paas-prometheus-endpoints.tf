resource "aws_iam_user" "paas_prometheus_endpoints" {
  name = "paas-prometheus-endpoints-${var.env}"

  force_destroy = true
}

resource "aws_iam_user_group_membership" "paas_prometheus_endpoints" {
  user   = aws_iam_user.paas_prometheus_endpoints.name
  groups = ["paas-prometheus-endpoints"]
}

resource "aws_iam_access_key" "paas_prometheus_endpoints" {
  user = aws_iam_user.paas_prometheus_endpoints.name
}
