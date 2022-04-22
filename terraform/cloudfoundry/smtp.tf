# we send emails via SES in *one* region and the IAM user must be
# created in that region for the ses_smtp_password_v4 to be generated
# correctly
provider "aws" {
  alias  = "ses-region"
  region = "eu-west-1"
}

resource "aws_iam_user" "ses_smtp" {
  provider = aws.ses-region

  name = "ses-smtp-${var.env}"

  force_destroy = true
}

resource "aws_iam_user_group_membership" "ses_smtp" {
  provider = aws.ses-region

  user   = aws_iam_user.ses_smtp.name
  groups = ["email-senders"]
}

resource "aws_iam_access_key" "ses_smtp" {
  provider = aws.ses-region

  user = aws_iam_user.ses_smtp.name
}
