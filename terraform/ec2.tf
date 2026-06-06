resource "aws_launch_template" "main" {
  name = "${var.project_name}-launch-template"
  image_id                = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.launch_template.id]

  iam_instance_profile   {
    name= aws_iam_instance_profile.ec2_instance_profile.name
}
  user_data = base64encode(templatefile("user_data.sh", {
  project_name = var.project_name
  aws_region   = var.aws_region
}))

  tags = {
    Name = "${var.project_name}-launch_template"
  }
}