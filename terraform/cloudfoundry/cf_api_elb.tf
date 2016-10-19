resource "aws_elb" "cf_cc" {
  name = "${var.env}-cf-cc"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.cf_api_elb.id}",
  ]
  access_logs {
    bucket = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-cc"
    interval = 5
  }

  health_check {
    target = "HTTP:9022/info"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 9022
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}

resource "aws_elb" "cf_uaa" {
  name = "${var.env}-cf-uaa"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.cf_api_elb.id}",
  ]
  access_logs {
    bucket = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-uaa"
    interval = 5
  }

  health_check {
    target = "HTTP:8080/healthz"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}

resource "aws_elb" "cf_doppler" {
  name = "${var.env}-cf-doppler"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.cf_api_elb.id}",
  ]
  access_logs {
    bucket = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-doppler"
    interval = 5
  }

  health_check {
    target = "TCP:8081"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 8081
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}
