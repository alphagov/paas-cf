resource "aws_s3_bucket" "droplets-s3" {
  bucket = "${var.env}-cf-droplets"

  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_acl" "droplets-s3" {
  bucket = aws_s3_bucket.droplets-s3.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "droplets-s3" {
  bucket = aws_s3_bucket.droplets-s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "droplets-s3" {
  bucket = aws_s3_bucket.droplets-s3.id

  rule {
    id     = "Expire old previous versions"
    status = "Enabled"
    prefix = ""

    noncurrent_version_expiration {
      noncurrent_days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
  rule {
    id     = "Delete old incomplete multi-part uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}

resource "aws_s3_bucket" "buildpacks-s3" {
  bucket = "${var.env}-cf-buildpacks"

  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_acl" "buildpacks-s3" {
  bucket = aws_s3_bucket.buildpacks-s3.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "buildpacks-s3" {
  bucket = aws_s3_bucket.buildpacks-s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "buildpacks-s3" {
  bucket = aws_s3_bucket.buildpacks-s3.id

  rule {
    id     = "Expire old previous versions"
    status = "Enabled"
    prefix = ""


    noncurrent_version_expiration {
      noncurrent_days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
  rule {
    id     = "Delete old incomplete multi-part uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}
resource "aws_s3_bucket" "packages-s3" {
  bucket = "${var.env}-cf-packages"

  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_acl" "packages-s3" {
  bucket = aws_s3_bucket.packages-s3.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "packages-s3" {
  bucket = aws_s3_bucket.packages-s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "packages-s3" {
  bucket = aws_s3_bucket.packages-s3.id

  rule {
    id     = "Expire old previous versions"
    status = "Enabled"
    prefix = ""

    noncurrent_version_expiration {
      noncurrent_days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
  rule {
    id     = "Delete old incomplete multi-part uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}
resource "aws_s3_bucket" "resources-s3" {
  bucket = "${var.env}-cf-resources"

  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_acl" "resources-s3" {
  bucket = aws_s3_bucket.resources-s3.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "resources-s3" {
  bucket = aws_s3_bucket.resources-s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "resources-s3" {
  bucket = aws_s3_bucket.resources-s3.id

  rule {
    id     = "Expire old previous versions"
    status = "Enabled"
    prefix = ""

    noncurrent_version_expiration {
      noncurrent_days = 36
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
  rule {
    id     = "Delete old incomplete multi-part uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}
resource "aws_s3_bucket" "test-artifacts" {
  bucket        = "gds-paas-${var.env}-test-artifacts"
  force_destroy = "true"
}

resource "aws_s3_bucket_acl" "test-artifacts" {
  bucket = aws_s3_bucket.test-artifacts.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "test-artifacts" {
  bucket = aws_s3_bucket.test-artifacts.id


  rule {
    id     = "Expire old previous versions"
    status = "Enabled"
    prefix = ""

    expiration {
      days = 7
    }
  }
}

variable "elb_access_log_bucket_name" {
  default = "elb-access-log"
}

resource "aws_s3_bucket" "elb_access_log" {
  bucket        = "${var.assets_prefix}-${var.env}-${var.elb_access_log_bucket_name}"
  force_destroy = "true"
}

resource "aws_s3_bucket_acl" "elb_access_log" {
  bucket = aws_s3_bucket.elb_access_log.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "elb_access_log" {
  bucket = aws_s3_bucket.elb_access_log.id
  policy = templatefile("${path.module}/policies/elb_access_log_bucket.json.tpl", {
    bucket_name = "${var.assets_prefix}-${var.env}-${var.elb_access_log_bucket_name}",
    principal   = var.elb_account_ids[var.region]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "elb_access_log" {
  bucket = aws_s3_bucket.elb_access_log.id

  rule {
    id     = "Expire old previous versions"
    status = "Enabled"
    prefix = ""

    expiration {
      days = 30
    }
  }
}
