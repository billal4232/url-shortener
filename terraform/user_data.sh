#!/bin/bash
set -e

# Update system packages
yum update -y

# Fetch database credentials and config from SSM Parameter Store
DB_HOST=$(aws ssm get-parameter --name "/${project_name}/db_host" --query "Parameter.Value" --output text --region ${aws_region})
DB_NAME=$(aws ssm get-parameter --name "/${project_name}/db_name" --query "Parameter.Value" --output text --region ${aws_region})
DB_USER=$(aws ssm get-parameter --name "/${project_name}/db_username" --query "Parameter.Value" --output text --region ${aws_region})
DB_PORT=$(aws ssm get-parameter --name "/${project_name}/db_port" --query "Parameter.Value" --output text --region ${aws_region})
DB_PASSWORD=$(aws ssm get-parameter --name "/${project_name}/db_password" --query "Parameter.Value" --with-decryption --output text --region ${aws_region})
DOMAIN_NAME=$(aws ssm get-parameter --name "/${project_name}/domain_name" --query "Parameter.Value" --output text --region ${aws_region})

# Authenticate Docker to ECR using instance IAM role
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin 688600819246.dkr.ecr.eu-north-1.amazonaws.com

# Pull latest Flask app image from ECR
docker pull 688600819246.dkr.ecr.eu-north-1.amazonaws.com/url-shortener:latest

# Run Flask container with SSM credentials injected as environment variables
docker run -d \
  --name url-shortener \
  --restart always \
  -p 5000:5000 \
  -e DB_HOST=$DB_HOST \
  -e DB_NAME=$DB_NAME \
  -e DB_USER=$DB_USER \
  -e DB_PASSWORD=$DB_PASSWORD \
  -e DB_PORT=$DB_PORT \
  -e DOMAIN_NAME=$DOMAIN_NAME \
  688600819246.dkr.ecr.eu-north-1.amazonaws.com/url-shortener:latest

# Configure CloudWatch agent to collect Docker container logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "/${project_name}/flask-logs",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent with the above config
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s