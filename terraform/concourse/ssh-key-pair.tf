resource "aws_key_pair" "concourse_key_pair" {
  key_name   = "${var.env}_concourse_key_pair"
  public_key = "${file("${path.module}/concourse_id_rsa.pub")}"
}
