resource "aws_iam_user" "paas_admin_metrics" {
  name = "paas-admin-metrics-${var.env}"

  force_destroy = true
}

resource "aws_iam_user_group_membership" "paas_admin_metrics" {
  user   = "${aws_iam_user.paas_admin_metrics.name}"
  groups = ["paas-admin-metrics"]
}

resource "aws_iam_access_key" "paas_admin_metrics" {
  user = "${aws_iam_user.paas_admin_metrics.name}"
}
