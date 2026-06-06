resource "aws_db_subnet_group" "group_for_rds" {
  name       = "subnet_group_for_rds"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-subnet_group"
  }
}
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-rds"
  engine                 = "postgres"
  engine_version         = "16.9"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.group_for_rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  multi_az               = false

  tags = {
    Name = "${var.project_name}-rds"
  }
}