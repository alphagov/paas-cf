resource "aws_elb" "logsearch_ingestor" {
  name = "${var.env}-logsearch-ingestor"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal = "true"
  security_groups = [
    "${aws_security_group.logsearch_ingestor_elb.id}",
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

resource "aws_elb" "logsearch_es_master" {
  name = "${var.env}-logsearch-es-master"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal = "true"
  security_groups = [
    "${aws_security_group.logsearch_elastic_master_elb.id}",
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

resource "aws_elb" "logsearch_kibana" {
  name = "${var.env}-logsearch-kibana"
  subnets = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.logsearch_elb.id}",
  ]

  health_check {
    target = "TCP:5601"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port = 5601
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}
