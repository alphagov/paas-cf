resource "aws_iam_user" "ses_smtp" {
  name = "ses-smtp-${var.env}"

  force_destroy = true
}

resource "aws_iam_user_group_membership" "ses_smtp" {
  user   = "${aws_iam_user.ses_smtp.name}"
  groups = ["email-senders"]
}

resource "aws_iam_access_key" "ses_smtp" {
  user = "${aws_iam_user.ses_smtp.name}"
}
