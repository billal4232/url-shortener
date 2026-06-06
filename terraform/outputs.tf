output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_url" {
  value = "https://app.${var.domain_name}"
}

output "ec2_instance_id" {
  value = aws_instance.main.id
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

