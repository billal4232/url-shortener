resource "aws_cloudwatch_log_group" "flask_logs" {
  name              = "/${var.project_name}/flask-logs"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-flask-logs"
  }
}