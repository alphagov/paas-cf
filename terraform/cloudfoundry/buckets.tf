resource "aws_s3_bucket" "droplets-s3" {
    bucket = "${var.env}-cf-droplets"
    acl = "private"
    force_destroy = "true"
}

resource "aws_s3_bucket" "buildpacks-s3" {
    bucket = "${var.env}-cf-buildpacks"
    acl = "private"
    force_destroy = "true"
}

resource "aws_s3_bucket" "packages-s3" {
    bucket = "${var.env}-cf-packages"
    acl = "private"
    force_destroy = "true"
}

resource "aws_s3_bucket" "resources-s3" {
    bucket = "${var.env}-cf-resources"
    acl = "private"
    force_destroy = "true"
}
