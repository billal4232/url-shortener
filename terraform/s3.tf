resource "aws_s3_bucket" "project_bucket" {
  bucket = "urlshortener-s3-bucket"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}