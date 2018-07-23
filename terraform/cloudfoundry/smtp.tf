resource "aws_iam_user" "ses_smtp" {
  name = "ses-smtp-${var.env}"

  force_destroy = true
}

# Until this feature request is not solved https://github.com/terraform-providers/terraform-provider-aws/issues/113,
# `aws_iam_group_membership` will wipe all the other members from the
# shared group.
#
# The workaround is use aws cli:
#
#   aws iam add-user-to-group --user-name "ses-smtp-${DEPLOY_ENV}" --group-name ses-smtp
#
# We could do it using terraform provisioner local-exec calling out awscli
# but we want to avoid this pattern so we will do it in a script in
# the next step.
#
# Once they fix it upstream, we can replace it with this code:
#
# resource "aws_iam_group_membership" "ses_smtp" {
#    name = "ses_smtp"
#    group = "ses_smtp"
#    users = [
#        "${aws_iam_user.ses_smtp.name}",
#    ]
#    append = true
#}

resource "aws_iam_access_key" "ses_smtp" {
  user = "${aws_iam_user.ses_smtp.name}"
}
