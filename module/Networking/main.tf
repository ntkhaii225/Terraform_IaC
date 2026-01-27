# =============================================================================
# Networking Module - VPC, Subnets, and Related Resources
# =============================================================================

# -----------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# Đây là mạng ảo riêng của bạn trên AWS, tách biệt với các tài khoản khác
# CIDR 10.0.0.0/16 cho phép tạo ~65,536 địa chỉ IP (10.0.0.0 - 10.0.255.255)
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# Cổng kết nối giữa VPC và Internet
# Chỉ public subnet mới có thể truy cập internet thông qua IGW này
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Public Subnet (10.0.1.0/24)
# Subnet công khai - instances ở đây có thể nhận public IP và truy cập internet
# Thường đặt: Load Balancer, Bastion Host, NAT Gateway
# CIDR 10.0.1.0/24 cho phép 256 địa chỉ IP (10.0.1.0 - 10.0.1.255)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # Tự động gán public IP cho instances

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Type        = "Public"
  }
}

# -----------------------------------------------------------------------------
# Private Subnet (10.0.2.0/24)
# Subnet riêng tư - instances ở đây KHÔNG có public IP, không truy cập trực tiếp từ internet
# Thường đặt: ECS Tasks, RDS Database, Backend Services
# CIDR 10.0.2.0/24 cho phép 256 địa chỉ IP (10.0.2.0 - 10.0.2.255)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Type        = "Private"
  }
}

# -----------------------------------------------------------------------------
# Route Table cho Public Subnet
# Định tuyến traffic: 0.0.0.0/0 (tất cả) -> Internet Gateway
# Cho phép public subnet giao tiếp với internet
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# =============================================================================
# NAT Gateway - Cho phép private subnet truy cập internet
# Chi phí: ~$32/tháng (rẻ hơn VPC Endpoints)
# =============================================================================

# -----------------------------------------------------------------------------
# Interface VPC Endpoints (PrivateLink)
# REMOVED: Replaced by NAT Instance
# -----------------------------------------------------------------------------


# 3. CloudWatch Logs (Container Logs) - Disabled to save cost
# resource "aws_vpc_endpoint" "logs" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.aws_region}.logs"
#   vpc_endpoint_type = "Interface"
#
#   subnet_ids         = [aws_subnet.private.id, aws_subnet.private_2.id]
#   security_group_ids = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#
#   tags = {
#     Name        = "${var.project_name}-logs-endpoint"
#     Environment = var.environment
#   }
# }

# -----------------------------------------------------------------------------
# Route Table cho Private Subnet
# -----------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Đã xoá route 0.0.0.0/0 -> NAT Gateway
  # Traffic S3 sẽ tự động được định tuyến qua Gateway Endpoint (nhờ prefix list)

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# Gắn route table vào subnet tương ứng
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------------------------------------------
# Public Subnet 2 (10.0.3.0/24) - Availability Zone 2
# Subnet công khai thứ 2 cho ALB (ALB yêu cầu ít nhất 2 public subnets ở 2 AZs)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-2"
    Environment = var.environment
    Type        = "Public"
  }
}

# -----------------------------------------------------------------------------
# Private Subnet 2 (10.0.4.0/24) - Availability Zone 2
# Subnet riêng tư thứ 2 cho ECS tasks/backend services
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = var.availability_zone_2

  tags = {
    Name        = "${var.project_name}-private-subnet-2"
    Environment = var.environment
    Type        = "Private"
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations cho Subnet 2
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------------------------------------------
# VPC Endpoint for S3 (Gateway Type)
# Cho phép truy cập S3 qua mạng nội bộ AWS, miễn phí và bảo mật
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Tự động thêm route vào bảng định tuyến private
  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name        = "${var.project_name}-s3-vpc-endpoint"
    Environment = var.environment
  }
}
