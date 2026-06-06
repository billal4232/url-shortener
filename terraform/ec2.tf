resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  user_data = templatefile("user_data.sh", {
  project_name = var.project_name
  aws_region   = var.aws_region
  s3_bucket    = aws_s3_bucket.project_bucket.bucket
})

  tags = {
    Name = "${var.project_name}-ec2"
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
}