resource "aws_key_pair" "bosh_ssh_key_pair" {
  key_name = "${var.env}_bosh_ssh_key_pair"
  public_key = "${file("${path.module}/bosh_id_rsa.pub")}"
}
