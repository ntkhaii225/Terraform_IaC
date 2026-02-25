# =============================================================================
# Bastion Host Module - EC2 Instance for SSH Access
# =============================================================================

# -----------------------------------------------------------------------------
# Data source: Lấy AMI Amazon Linux 2023 mới nhất
# -----------------------------------------------------------------------------

# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-*-x86_64"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# -----------------------------------------------------------------------------
# Key Pair cho SSH access
# Bạn cần tạo key pair trước hoặc import public key
# -----------------------------------------------------------------------------
resource "aws_key_pair" "bastion" {
  key_name   = "${var.project_name}-bastion-key"
  public_key = var.public_key

  tags = {
    Name        = "${var.project_name}-bastion-key"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance - Bastion Host
# Đặt trong Public Subnet để có thể SSH từ internet
# -----------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = "ami-0fa77c6a18df84736"
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_security_group_id]
  key_name                    = aws_key_pair.bastion.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 16
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # IMDSv2 Required
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name        = "${var.project_name}-bastion"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# -----------------------------------------------------------------------------
# IAM Role and Permissions for Jenkins (ECR & ECS Access)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "bastion_role" {
  name = "${var.project_name}-bastion-role"

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
    Name        = "${var.project_name}-bastion-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_full_access" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.project_name}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}
