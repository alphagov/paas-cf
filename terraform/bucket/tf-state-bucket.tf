provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "terraform-state-s3" {
  bucket        = "${var.env}-state"
  acl           = "private"
  force_destroy = "true"

  versioning {
    enabled = true
  }
}
