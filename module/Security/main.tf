# =============================================================================
# Security Groups Module - ALB, ECS, Bastion Security Groups
# =============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Inbound: HTTP 80 từ anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-alb"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-sg-ecs"
  description = "Security group for ECS instances (EC2)"
  vpc_id      = var.vpc_id

  # Inbound: Port 3000 từ ALB (cho Frontend containers)
  ingress {
    description     = "Frontend port from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Inbound: Port 8080 từ ALB (cho Backend containers)
  ingress {
    description     = "Backend port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Inbound: Dynamic ports từ ALB (nếu dùng dynamic port mapping)
  ingress {
    description     = "Dynamic ports from ALB for containers"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Inbound: SSH từ Bastion (để troubleshoot ECS instances)
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Inbound: MySQL 3306 từ Bastion (để truy cập Database)
  ingress {
    description     = "MySQL from Bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Inbound: Redis 6379 từ Bastion (để truy cập Cache)
  ingress {
    description     = "Redis from Bastion"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Outbound: Cho phép tất cả traffic ra ngoài
  # (Cần thiết để pull images từ ECR, gọi APIs, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-ecs"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Security Group cho Bastion Host (d-sg-FUEC-bastion)
# - Cho phép SSH 22 từ My PC
# - Cho phép kết nối đến ECS/RDS trên port 3306
# -----------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "Security group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from My PC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-bastion"
    Environment = var.environment
  }
}
