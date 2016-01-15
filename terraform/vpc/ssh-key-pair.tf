resource "aws_key_pair" "env_key_pair" {
  key_name = "${var.env}_key_pair"
  public_key = "${file("${path.module}/id_rsa.pub")}"
}
