resource "aws_iam_user" "metrics_exporter" {
  name = "metrics-exporter-${var.env}"

  force_destroy = true
}

resource "aws_iam_user_group_membership" "metrics_exporter" {
  user   = "${aws_iam_user.metrics_exporter.name}"
  groups = ["metrics-exporters"]
}

resource "aws_iam_access_key" "metrics_exporter" {
  user = "${aws_iam_user.metrics_exporter.name}"
}
