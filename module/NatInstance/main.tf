# =============================================================================
# NAT Instance Module
# EC2 Instance configured to act as a NAT Router
# =============================================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nat" {
  name        = "${var.project_name}-nat-sg"
  description = "Security Group for NAT Instance"
  vpc_id      = var.vpc_id

  # Inbound: Allow all traffic from Private Subnets
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_subnet_cidrs
    description = "Allow traffic from Private Subnets"
  }

  # Inbound: SSH from Bastion (optional, for debugging)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
    description     = "Allow SSH from Bastion"
  }

  # Outbound: Allow all traffic to Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-nat-sg"
    Environment = var.environment
  }
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.nano"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.nat.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Enable IP Forwarding
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
              sysctl -p

              # Install iptables services
              yum install -y iptables-services

              # Configure NAT (Masquerade)
              iptables -t nat -A POSTROUTING -o enX0 -j MASQUERADE
              iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              
              # Save rules
              service iptables save
              systemctl enable iptables
              systemctl start iptables
              EOF
  )

  tags = {
    Name        = "${var.project_name}-nat-instance"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

resource "aws_eip_association" "nat_eip_assoc" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}
