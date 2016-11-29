resource "aws_key_pair" "bosh_lite_key_pair" {
  key_name   = "${var.env}-bosh-lite-ssh-key-pair"
  public_key = "${var.bosh_lite_ssh_key}"
}
