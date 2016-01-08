resource "aws_elb" "concourse" {
  name            = "${var.env}-concourse"
  subnets         = ["${var.subnet0_id}"]
  security_groups = ["${aws_security_group.concourse-elb.id}"]

  health_check {
    target              = "TCP:8080"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  listener {
    instance_port       = 8080
    instance_protocol   = "http"
    lb_port             = 443
    lb_protocol         = "https"
    ssl_certificate_id  = "${var.concourse_elb_cert_arn}"
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

resource "aws_route53_record" "concourse" {
  zone_id = "${var.dns_zone_id}"
  name    = "${var.env}-concourse.${var.dns_zone_name}."
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_elb.concourse.dns_name}"]
}
