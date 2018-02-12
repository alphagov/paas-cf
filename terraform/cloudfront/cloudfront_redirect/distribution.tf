variable "redirect_methods" {
  default = ["GET", "HEAD"]
}

resource "aws_api_gateway_rest_api" "redirect_api_gw" {
  name        = "${var.name}-redirect_api_gw"
  description = "Basic redirect for ${var.name}"
}

resource "aws_api_gateway_method" "redirect_api_gw" {
  count            = "${length(var.redirect_methods)}"
  rest_api_id      = "${aws_api_gateway_rest_api.redirect_api_gw.id}"
  resource_id      = "${aws_api_gateway_rest_api.redirect_api_gw.root_resource_id}"
  http_method      = "${element(var.redirect_methods, count.index)}"
  api_key_required = false
  authorization    = "NONE"
}

resource "aws_api_gateway_integration" "redirect_api_gw" {
  count                = "${length(var.redirect_methods)}"
  rest_api_id          = "${aws_api_gateway_rest_api.redirect_api_gw.id}"
  resource_id          = "${aws_api_gateway_rest_api.redirect_api_gw.root_resource_id}"
  http_method          = "${element(aws_api_gateway_method.redirect_api_gw.*.http_method, count.index)}"
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "redirect_api_gw" {
  count       = "${length(var.redirect_methods)}"
  rest_api_id = "${aws_api_gateway_rest_api.redirect_api_gw.id}"
  resource_id = "${aws_api_gateway_rest_api.redirect_api_gw.root_resource_id}"
  http_method = "${element(aws_api_gateway_method.redirect_api_gw.*.http_method, count.index)}"
  status_code = "301"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Location"                  = true
    "method.response.header.Strict-Transport-Security" = true
  }
}

resource "aws_api_gateway_integration_response" "redirect_api_gw" {
  count             = "${length(var.redirect_methods)}"
  rest_api_id       = "${aws_api_gateway_rest_api.redirect_api_gw.id}"
  resource_id       = "${aws_api_gateway_rest_api.redirect_api_gw.root_resource_id}"
  http_method       = "${element(aws_api_gateway_method.redirect_api_gw.*.http_method, count.index)}"
  status_code       = "${element(aws_api_gateway_method_response.redirect_api_gw.*.status_code, count.index)}"
  selection_pattern = ""

  response_parameters = {
    "method.response.header.Location"                  = "'${var.redirect_target}'"
    "method.response.header.Strict-Transport-Security" = "'max-age=10886400; includeSubDomains; preload'"
  }
}

resource "aws_api_gateway_deployment" "redirect_api_gw" {
  depends_on = [
    "aws_api_gateway_integration.redirect_api_gw",
    "aws_api_gateway_integration_response.redirect_api_gw",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.redirect_api_gw.id}"
  stage_name  = "redirect"

  variables = {
    # something in this resource needs to change to
    # pick up changes to the `aws_api_gateway_method*`
    # and `aws_api_gateway_integration*` resources,
    # otherwise your changes won't be deployed
    version = "0.0.1"
  }
}

resource "aws_cloudfront_distribution" "simple_redirect" {
  origin {
    # TODO: Where can I get this name???
    domain_name = "${aws_api_gateway_rest_api.redirect_api_gw.id}.execute-api.eu-west-1.amazonaws.com"
    origin_path = "/redirect"
    origin_id   = "redirect_api_gw"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  aliases         = "${var.aliases}"
  comment         = "Redirection ${join(",", var.aliases)} to ${var.redirect_target}"
  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "redirect_api_gw"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 5
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    Environment = "${var.env}"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    iam_certificate_id             = "${var.domain_cert_id}"
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
}
