resource "aws_iam_server_certificate" "concourse" {
  name = "${var.env}-concourse"
  certificate_body = "${file("concourse.crt")}"
  private_key = "${file("concourse.key")}"
}

resource "aws_elb" "concourse" {
  name            = "${var.env}-concourse"
  subnets         = ["${split(",", var.infra_subnet_ids)}"]
  security_groups = ["${aws_security_group.concourse-elb.id}"]
  idle_timeout    = 600

  health_check {
    target              = "TCP:8080"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    instance_port       = 8080
    instance_protocol   = "tcp"
    lb_port             = 443
    lb_protocol         = "ssl"
    ssl_certificate_id  = "${aws_iam_server_certificate.concourse.arn}"
  }

  tags {
    Name = "${var.env}-concourse-elb"
  }
}

resource "aws_security_group" "concourse-elb" {
  name        = "${var.env}-concourse-elb"
  description = "Concourse ELB security group"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["${split(",", var.office_cidrs)}"]
  }

  tags {
    Name = "${var.env}-concourse-elb"
  }
}

resource "aws_route53_record" "deployer-concourse" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "deployer.${var.env}.${var.system_dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.concourse.dns_name}"]
}
