resource "aws_codecommit_repository" "concourse-pool" {
  provider = "aws.codecommit"
  repository_name = "concourse-pool-${var.env}"
  description = "Git repository to keep concourse pool resource locks"
  default_branch = "master"
}
