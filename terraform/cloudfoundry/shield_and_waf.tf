resource "aws_shield_protection" "shield_for_app_gorouter_alb" {
  name = "${var.env}-app-gorouter-shield"
  resource_arn = "${aws_lb.cf_router_app_domain.arn}"
}

resource "aws_shield_protection" "shield_for_system_gorouter_alb" {
  name = "${var.env}-system-gorouter-shield"
  resource_arn = "${aws_lb.cf_router_system_domain.arn}"
}
