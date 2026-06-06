resource "aws_autoscaling_group" "main" {
  name                      = "${var.project_name}-asg"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.alb_tg.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  depends_on = [
  aws_db_instance.main,
  aws_nat_gateway.main,
  aws_ssm_parameter.db_host,
  aws_ssm_parameter.db_name,
  aws_ssm_parameter.db_username,
  aws_ssm_parameter.db_port,
  aws_ssm_parameter.db_password
]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
resource "aws_autoscaling_policy" "alb_request_count" {
  name                   = "${var.project_name}-alb-request-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.alb_tg.arn_suffix}"
    }
    target_value = 100.0
  }
}