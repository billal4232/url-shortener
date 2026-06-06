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