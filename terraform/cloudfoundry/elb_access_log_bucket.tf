variable "elb_access_log_bucket_name" {
  default     = "elb-access-log"
}

resource "template_file" "elb_access_log_bucket_policy" {
  template = "${file("${path.module}/policies/elb_access_log_bucket.json.tpl")}"
  vars {
    bucket_name = "${var.assets_prefix}-${var.env}-${var.elb_access_log_bucket_name}"
    principal = "${lookup(var.elb_account_ids, var.region)}"
  }
}

resource "aws_s3_bucket" "elb_access_log" {
    bucket = "${var.assets_prefix}-${var.env}-${var.elb_access_log_bucket_name}"
    acl = "private"
    force_destroy = "true"
    policy = "${template_file.elb_access_log_bucket_policy.rendered}"

    lifecycle_rule {
      enabled = true
      prefix = ""
      expiration {
        days = 30
      }
    }
}
