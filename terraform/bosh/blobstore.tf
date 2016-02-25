resource "aws_s3_bucket" "bosh-blobstore" {
  bucket = "${var.env}-bosh-blobstore"
  acl = "private"
  force_destroy = "true"
}
