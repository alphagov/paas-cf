variable "key-name" {
  description = "A name for the key to be uploaded to EC2 key pairs"
}

resource "aws_key_pair" "bosh-init" {
  key_name = "${var.key-name}"
  public_key = "${file("bosh-init-key/id_rsa.pub")}"
}
