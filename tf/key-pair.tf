resource "aws_key_pair" "cloudfoundry" {
  key_name = "${var.env}-key" 
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}
