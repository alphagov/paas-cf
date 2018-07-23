resource "aws_iam_user" "metrics_exporter" {
  name = "metrics-exporter-${var.env}"

  force_destroy = true
}

# Until this feature request is not solved https://github.com/terraform-providers/terraform-provider-aws/issues/113,
# `aws_iam_group_membership` will wipe all the other members from the
# shared group.
#
# The workaround is use aws cli:
#
#   aws iam add-user-to-group --user-name "metrics-exporter-${DEPLOY_ENV}" --group-name metrics-exporters
#
# We could do it using terraform provisioner local-exec calling out awscli
# but we want to avoid this pattern so we will do it in a script in
# the next step.

resource "aws_iam_access_key" "metrics_exporter" {
  user = "${aws_iam_user.metrics_exporter.name}"
}
