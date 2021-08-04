resource "aws_subnet" "main" {
  availability_zone = "${var.region}${var.zone}"
  cidr_block        = var.cidr
  vpc_id            = var.vpc_id

  map_public_ip_on_launch = true

  tags = {
    Name = "az-healthcheck/${var.zone}"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = var.aws_route_table_id
}

resource "aws_security_group" "access_sg" {
  name        = "az-healthcheck/${var.zone}"
  description = "Security group for AZ Healthchecks allowing access"
  vpc_id      = aws_subnet.main.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "az-healthcheck/${var.zone}"
  }
}

resource "aws_instance" "healthcheck" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id

  availability_zone = "${var.region}${var.zone}"
  vpc_security_group_ids = [
    aws_security_group.access_sg.id,
  ]

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    su - ec2-user
    docker run -d -p 3000:3000 ghcr.io/alphagov/paas/simple-healthcheck
  EOF

  tags = {
    Name = "az-healthcheck/${var.zone}"
  }

  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = true
}
