resource "aws_s3_bucket" "droplets-s3" {
  bucket        = "${var.env}-cf-droplets"
  acl           = "private"
  force_destroy = "true"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "Expire old previous versions"
    enabled = true
    prefix  = ""

    noncurrent_version_expiration {
      days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload_days = "3"
  }
}

resource "aws_s3_bucket" "buildpacks-s3" {
  bucket        = "${var.env}-cf-buildpacks"
  acl           = "private"
  force_destroy = "true"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "Expire old previous versions"
    enabled = true
    prefix  = ""

    noncurrent_version_expiration {
      days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload_days = "3"
  }
}

resource "aws_s3_bucket" "packages-s3" {
  bucket        = "${var.env}-cf-packages"
  acl           = "private"
  force_destroy = "true"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "Expire old previous versions"
    enabled = true
    prefix  = ""

    noncurrent_version_expiration {
      days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload_days = "3"
  }
}

resource "aws_s3_bucket" "resources-s3" {
  bucket        = "${var.env}-cf-resources"
  acl           = "private"
  force_destroy = "true"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "Expire old previous versions"
    enabled = true
    prefix  = ""

    noncurrent_version_expiration {
      days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload_days = "3"
  }
}

resource "aws_s3_bucket" "test-artifacts" {
  bucket        = "gds-paas-${var.env}-test-artifacts"
  acl           = "private"
  force_destroy = "true"

  lifecycle_rule {
    enabled = true
    prefix  = ""

    expiration {
      days = 7
    }
  }
}

variable "elb_access_log_bucket_name" {
  default = "elb-access-log"
}

data "template_file" "elb_access_log_bucket_policy" {
  template = "${file("${path.module}/policies/elb_access_log_bucket.json.tpl")}"

  vars {
    bucket_name = "${var.assets_prefix}-${var.env}-${var.elb_access_log_bucket_name}"
    principal   = "${lookup(var.elb_account_ids, var.region)}"
  }
}

resource "aws_s3_bucket" "elb_access_log" {
  bucket        = "${var.assets_prefix}-${var.env}-${var.elb_access_log_bucket_name}"
  acl           = "private"
  force_destroy = "true"
  policy        = "${data.template_file.elb_access_log_bucket_policy.rendered}"

  lifecycle_rule {
    enabled = true
    prefix  = ""

    expiration {
      days = 30
    }
  }
}
