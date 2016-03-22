resource "aws_codecommit_repository" "concourse-pool" {
  provider = "aws.codecommit"
  repository_name = "concourse-pool-${var.env}"
  description = "Git repository to keep concourse pool resource locks"
  default_branch = "master"
}

resource "aws_iam_user" "git" {
  name = "git-${var.env}"
}

# Until this feature request is not solved https://github.com/hashicorp/terraform/issues/5778,
# `aws_iam_group_membership` will wipe all the other members from the
# shared group.
#
# The workaround is use aws cli:
#
#   aws iam add-user-to-group --user-name git-${DEPLOY_ENV} --group-name concourse-pool-git-rw
#
# We could do it using terraform provisioner local-exec calling out awscli
# but we want to avoid this pattern so we will do it in a script in
# the next step.
#
# Once they fix it upstream, we can replace it with this code:
#
# resource "aws_iam_group_membership" "concourse-pool-git-rw" {
#    name = "concourse-pool-git-rw"
#    group = "concourse-pool-git-rw"
#    users = [
#        "${aws_iam_user.git.name}",
#    ]
#    append = true
#}

resource "aws_iam_user_ssh_key" "git" {
  username = "${aws_iam_user.git.name}"
  encoding = "PEM"
  public_key = "${var.git_rsa_id_pub}"
}
