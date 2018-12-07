resource "aws_iam_user" "yace" {
  name = "yace-${var.env}"

  force_destroy = true
}

resource "aws_iam_user_group_membership" "yace" {
  user   = "${aws_iam_user.yace.name}"
  groups = ["cloudwatch-exporter"]
}

resource "aws_iam_access_key" "yace" {
  user = "${aws_iam_user.yace.name}"
}
