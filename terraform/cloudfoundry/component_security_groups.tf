
resource "aws_security_group" "cloud_controller" {
  name = "${var.env}-cloud-controller"
  description = "Group for VMs acting as part of the Cloud Controller"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.env}-cloud-controller"
  }
}
