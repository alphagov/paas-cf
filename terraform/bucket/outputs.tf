output "environment" {
  value = "${var.env}"
}

output "region" {
  value = "${var.region}"
}

output "bucket" {
  value = "${aws_s3_bucket.terraform-state-s3.id}"
}
