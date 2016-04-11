resource "aws_elb" "ingestor_elb" {
  name = "${var.env}-ingestor-elb"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal = "true"
  security_groups = [
    "${aws_security_group.ingestor_elb.id}",
  ]

  health_check {
    target = "TCP:5514"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 5514
    instance_protocol = "tcp"
    lb_port = 5514
    lb_protocol = "tcp"
  }
  listener {
    instance_port = 2514
    instance_protocol = "tcp"
    lb_port = 2514
    lb_protocol = "tcp"
  }
}

resource "aws_elb" "es_master_elb" {
  name = "${var.env}-cf-es-elb"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal = "true"
  security_groups = [
    "${aws_security_group.elastic_master_elb.id}",
  ]

  health_check {
    target = "TCP:9200"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 9200
    instance_protocol = "tcp"
    lb_port = 9200
    lb_protocol = "tcp"
  }
}

resource "aws_iam_server_certificate" "logsearch" {
  name_prefix = "${var.env}-logsearch-"
  certificate_body = "${file("generated-certificates/logsearch.crt")}"
  private_key = "${file("generated-certificates/logsearch.key")}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "logsearch_elb" {
  name = "${var.env}-logsearch-elb"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.logsearch_elb.id}",
  ]

  health_check {
    target = "TCP:5602"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port = 5602
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${aws_iam_server_certificate.logsearch.arn}"
  }
}
