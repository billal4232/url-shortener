resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]
  
  tags = {
    Name = "${var.project_name}-acm_cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate" "cert_us_east_1" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]

  tags = {
    Name = "${var.project_name}-acm-cert-us-east-1"
  }

  lifecycle {
    create_before_destroy = true
  }
}