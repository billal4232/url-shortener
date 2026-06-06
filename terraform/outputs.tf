output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_url" {
  value = "https://app.${var.domain_name}"
}

output "asg_name" {
  value = aws_autoscaling_group.main.name
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

