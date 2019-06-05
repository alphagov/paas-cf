resource "aws_elb" "s3_broker" {
  name                      = "${var.env}-s3-broker"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal                  = true
  security_groups           = ["${aws_security_group.service_brokers.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-broker-s3"
    interval      = 5
  }

  health_check {
    target              = "HTTP:80/healthcheck"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.system.arn}"
  }
}

resource "aws_lb_ssl_negotiation_policy" "s3_broker" {
  name          = "paas-${random_pet.elb_cipher.keepers.default_elb_security_policy}-${random_pet.elb_cipher.id}"
  load_balancer = "${aws_elb.s3_broker.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${random_pet.elb_cipher.keepers.default_elb_security_policy}"
  }
}

data "template_file" "s3_broker_user_ip_restriction" {
  template = "${file("${path.module}/policies/s3_broker_user_ip_restriction.json.tpl")}"

  vars {
    nat_gateway_public_ips = "${jsonencode(aws_nat_gateway.cf.*.public_ip)}"
  }
}

resource "aws_iam_policy" "s3_broker_user_ip_restriction" {
  policy      = "${data.template_file.s3_broker_user_ip_restriction.rendered}"
  name        = "${var.env}S3BrokerUserIpRestriction"
  description = "Restricts S3 API Access to just the NAT Gateway IPs"
}
