resource "aws_instance" "bastion" {
  ami = "${lookup(var.ubuntu_amis, var.region)}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.infra.0.id}"
  private_ip = "10.0.0.4"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  key_name = "${aws_key_pair.cloudfoundry.key_name}"
  source_dest_check = false
  user_data = "#cloud-config\nhostname: ${var.env}-bastion"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${var.env}-bastion"
  }

  connection {
    user = "ubuntu"
    key_file = "~/.ssh/id_rsa"
  }

}
