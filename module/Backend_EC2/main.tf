# =============================================================================
# Backend EC2 Module
# EC2 Instance chạy .NET Core API trong Private Subnet
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source: Amazon Linux 2023 AMI
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu official)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# IAM Role for Backend EC2
# Quyền truy cập S3 (upload/download) và SSM (remote management)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "backend" {
  name = "${var.project_name}-backend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-backend-ec2-role"
    Environment = var.environment
  }
}

# SSM Managed Instance Core - Cho phép SSM Session Manager
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.backend.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 Access Policy
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-backend-s3-policy"
  description = "Allow backend EC2 to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*",
          var.s3_artifact_bucket_arn,
          "${var.s3_artifact_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.backend.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "backend" {
  name = "${var.project_name}-backend-ec2-profile"
  role = aws_iam_role.backend.name
}

# -----------------------------------------------------------------------------
# EC2 Instance - Backend API Server
# -----------------------------------------------------------------------------
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.backend_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.backend.name
  key_name               = var.key_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # ============================================
    # Update package list
    # ============================================
    apt-get update -y

    # ============================================
    # Install .NET 8 Runtime (Ubuntu 24.04)
    # ============================================
    apt-get install -y wget apt-transport-https software-properties-common
    wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    dpkg -i /tmp/packages-microsoft-prod.deb
    apt-get update -y
    apt-get install -y aspnetcore-runtime-8.0

    # ============================================
    # Install AWS CLI (for S3 artifact download)
    # ============================================
    apt-get install -y unzip curl
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # ============================================
    # Create application directory
    # ============================================
    mkdir -p /app/backend
    chown ubuntu:ubuntu /app/backend

    # ============================================
    # Create systemd service for auto-start/restart
    # ============================================
    cat > /etc/systemd/system/backend.service << 'SERVICE'
    [Unit]
    Description=FUEC Backend API (.NET Core)
    After=network.target

    [Service]
    Type=simple
    User=ubuntu
    WorkingDirectory=/app/backend
    ExecStart=/usr/bin/dotnet /app/backend/FUEC.API.dll
    Restart=always
    RestartSec=10

    # Environment variables
    Environment=ASPNETCORE_ENVIRONMENT=${var.aspnetcore_environment}
    Environment=ASPNETCORE_URLS=http://+:${var.backend_port}
    Environment=MYSQL_HOST=${var.mysql_host}
    Environment=MYSQL_DATABASE=${var.mysql_database}
    Environment=MYSQL_USER=${var.mysql_user}
    Environment=MYSQL_PASSWORD=${var.mysql_password}
    Environment=MYSQL_PORT=${var.mysql_port}
    Environment=ConnectionStrings__DefaultConnection=Server=${var.mysql_host};Port=${var.mysql_port};Database=${var.mysql_database};User=${var.mysql_user};Password=${var.mysql_password};
    Environment=AWS__S3__BucketName=${var.s3_bucket_name}
    Environment=AWS__Region=${var.aws_region}

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable backend.service

    echo "Backend EC2 setup complete" >> /var/log/user-data.log
  EOF
  )

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-backend"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
