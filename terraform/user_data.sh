#!/bin/bash
set -e

# Update system
yum update -y

# Install Python and dependencies
yum install -y python3 python3-pip python3-virtualenv

# Create app directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Create and activate venv
python3 -m venv venv
source venv/bin/activate

# Install Flask and psycopg2 inside venv
pip install flask psycopg2-binary

# Fetch SSM parameters
DB_HOST=$(aws ssm get-parameter --name "/${project_name}/db_host" --query "Parameter.Value" --output text --region ${aws_region})
DB_NAME=$(aws ssm get-parameter --name "/${project_name}/db_name" --query "Parameter.Value" --output text --region ${aws_region})
DB_USER=$(aws ssm get-parameter --name "/${project_name}/db_username" --query "Parameter.Value" --output text --region ${aws_region})
DB_PORT=$(aws ssm get-parameter --name "/${project_name}/db_port" --query "Parameter.Value" --output text --region ${aws_region})
DB_PASSWORD=$(aws ssm get-parameter --name "/${project_name}/db_password" --query "Parameter.Value" --with-decryption --output text --region ${aws_region})
DOMAIN_NAME=$(aws ssm get-parameter --name "/${project_name}/domain_name" --query "Parameter.Value" --output text --region ${aws_region})

# Write environment variables for systemd
echo "DB_HOST=$DB_HOST" > /etc/flask.env
echo "DB_NAME=$DB_NAME" >> /etc/flask.env
echo "DB_USER=$DB_USER" >> /etc/flask.env
echo "DB_PORT=$DB_PORT" >> /etc/flask.env
echo "DB_PASSWORD=$DB_PASSWORD" >> /etc/flask.env
echo "DOMAIN_NAME=$DOMAIN_NAME" >> /etc/flask.env

# Pull app.py from S3
aws s3 cp s3://${s3_bucket}/app.py /home/ec2-user/app/app.py --region ${aws_region}

# Set correct ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

# Create Flask log directory
mkdir -p /var/log/flask
chown ec2-user:ec2-user /var/log/flask

# Create systemd service
cat > /etc/systemd/system/flask.service <<EOF
[Unit]
Description=Flask Application
After=network-online.target
Wants=network-online.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/app
EnvironmentFile=/etc/flask.env
ExecStart=/home/ec2-user/app/venv/bin/python /home/ec2-user/app/app.py
StandardOutput=append:/var/log/flask/app.log
StandardError=append:/var/log/flask/app.log
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Flask service
systemctl daemon-reload
systemctl enable flask
systemctl start flask

# Install and configure CloudWatch Agent
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/flask/app.log",
            "log_group_name": "/${project_name}/flask-logs",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s