variable "pingdom_probe_cidrs_0" {
  description = "CSV of additional CIDR addresses for which we allow web access, provided externally"
  default     = ""
}

variable "pingdom_probe_cidrs_1" {
  description = "CSV of additional CIDR addresses for which we allow web access, provided externally"
  default     = ""
}

variable "pingdom_probe_cidrs_2" {
  description = "CSV of additional CIDR addresses for which we allow web access, provided externally"
  default     = ""
}

variable "pingdom_probe_cidrs_3" {
  description = "CSV of additional CIDR addresses for which we allow web access, provided externally"
  default     = ""
}

resource "aws_security_group" "pingdom-probes-0" {
  name        = "${var.env}-cf-pingdom-probes-0"
  description = "Security group for pingdom probes to reach the HTTPS port"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${split(",", var.pingdom_probe_cidrs_0)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-pingdom-probes-0"
  }
}

resource "aws_security_group" "pingdom-probes-1" {
  name        = "${var.env}-cf-pingdom-probes-1"
  description = "Security group for pingdom probes to reach the HTTPS port"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${split(",", var.pingdom_probe_cidrs_1)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-pingdom-probes-1"
  }
}

resource "aws_security_group" "pingdom-probes-2" {
  name        = "${var.env}-cf-pingdom-probes-2"
  description = "Security group for pingdom probes to reach the HTTPS port"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${split(",", var.pingdom_probe_cidrs_2)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-pingdom-probes-2"
  }
}

resource "aws_security_group" "pingdom-probes-3" {
  name        = "${var.env}-cf-pingdom-probes-3"
  description = "Security group for pingdom probes to reach the HTTPS port"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${split(",", var.pingdom_probe_cidrs_3)}",
    ]
  }

  tags {
    Name = "${var.env}-cf-pingdom-probes-3"
  }
}
