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
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    // https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html#ec2-instance-connect-setup-security-group
    cidr_blocks = ["18.202.216.48/29", "3.8.37.24/29"]
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

    echo '
[Unit]
Description=simple-healthcheck-service
Requires=docker.service
After=docker.service
[Service]
Restart=always
ExecStartPre=/bin/bash -c "/usr/bin/docker ps -q -f name=simple-healthcheck | grep -q . && /usr/bin/docker stop simple-healthcheck || true"
ExecStartPre=/bin/bash -c "/usr/bin/docker ps -aq -f name=simple-healthcheck | grep -q . && /usr/bin/docker rm simple-healthcheck || true"
ExecStart=/usr/bin/su ec2-user -c "/usr/bin/docker run --name simple-healthcheck -p 3000:3000 ghcr.io/alphagov/paas/simple-healthcheck"
Restart=on-failure
RestartSec=12s
[Install]
WantedBy=multi-user.target
' >/etc/systemd/system/simple-healthcheck.service

    systemctl daemon-reload
 
    yum update -y --setopt=retries=0
    amazon-linux-extras install docker -y --setopt=retries=0
    service docker start
    usermod -a -G docker ec2-user 
  
    sudo systemctl enable simple-healthcheck
    sudo systemctl start simple-healthcheck

  EOF
  user_data_replace_on_change = true

  tags = {
    Name = "az-healthcheck/${var.zone}"
  }

  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = true
}
