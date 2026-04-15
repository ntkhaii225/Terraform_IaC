# =============================================================================
# Root Module - Main Configuration
# Orchestrates all infrastructure modules
# =============================================================================

# -----------------------------------------------------------------------------
# Networking Module
# Creates VPC, Subnets, Internet Gateway, Route Tables
# -----------------------------------------------------------------------------
module "networking" {
  source = "../module/Networking"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  public_subnet_cidr_2  = var.public_subnet_cidr_2
  private_subnet_cidr   = var.private_subnet_cidr
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  availability_zone     = var.availability_zone
  availability_zone_2   = var.availability_zone_2
}

# -----------------------------------------------------------------------------
# Security Module
# Creates Security Groups for ALB, ECS/Backend, Bastion
# -----------------------------------------------------------------------------
module "security" {
  source = "../module/Security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}

# -----------------------------------------------------------------------------
# Application Load Balancer Module
# Phục vụ Backend API (Frontend đã chuyển sang S3 + CloudFront)
# -----------------------------------------------------------------------------
module "alb" {
  source = "../module/ALB"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  domain_name           = var.domain_name
}

# -----------------------------------------------------------------------------
# Bastion Host Module
# EC2 instance cho SSH access vào Private Subnet resources
# -----------------------------------------------------------------------------
module "bastion" {
  source = "../module/Bastion"

  project_name              = var.project_name
  environment               = var.environment
  public_subnet_id          = module.networking.public_subnet_id
  bastion_security_group_id = module.security.bastion_security_group_id
  instance_type             = var.bastion_instance_type
  public_key                = var.bastion_public_key
}

# -----------------------------------------------------------------------------
# NAT Instance Module (Cost-effective NAT thay cho NAT Gateway)
# Cho phép Private Subnet truy cập Internet
# -----------------------------------------------------------------------------
module "nat_instance" {
  source = "../module/NatInstance"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  public_subnet_id     = module.networking.public_subnet_id
  private_subnet_cidrs = [module.networking.private_subnet_cidr, module.networking.private_subnet_cidr_2]

  bastion_security_group_id = module.security.bastion_security_group_id
  key_name                  = module.bastion.key_name
}

# Route 0.0.0.0/0 -> NAT Instance ENI (for Private Subnets)
resource "aws_route" "private_internet_access" {
  route_table_id         = module.networking.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nat_instance.network_interface_id
}

# -----------------------------------------------------------------------------
# Database Module
# Creates RDS MySQL instance in Private Subnet
# -----------------------------------------------------------------------------
module "database" {
  source = "../module/Database"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  private_subnet_ids = module.networking.private_subnet_ids

  ecs_security_group_id     = module.security.ecs_security_group_id
  bastion_security_group_id = module.security.bastion_security_group_id

  db_name     = var.mysql_database
  db_username = var.mysql_user
  db_password = var.mysql_password
}

# -----------------------------------------------------------------------------
# Random Suffix for S3 Bucket
# -----------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# Storage Module (S3 - Application Data)
# S3 bucket cho upload/download files (ảnh, tài liệu, etc.)
# -----------------------------------------------------------------------------
module "storage" {
  source = "../module/Storage"

  bucket_name = "${var.project_name}-storage-${var.environment}-${random_string.suffix.result}"
  environment = var.environment
}

# -----------------------------------------------------------------------------
# Frontend S3 + CloudFront Module (MỚI)
# Host React SPA trên S3, phân phối qua CloudFront CDN
# CloudFront có 2 origins: S3 (frontend) + ALB (/api/*)
# -----------------------------------------------------------------------------
module "frontend_s3_cloudfront" {
  source = "../module/Frontend_S3_CloudFront"

  project_name        = var.project_name
  environment         = var.environment
  domain_name         = var.domain_name
  acm_certificate_arn = module.alb.acm_certificate_arn
  alb_dns_name        = module.alb.alb_dns_name
  alb_zone_id         = module.alb.alb_zone_id
  alb_domain_name     = "alb.${var.domain_name}"
}

# -----------------------------------------------------------------------------
# Backend EC2 Module (MỚI - Thay thế ECS Backend)
# EC2 instance chạy .NET Core API trong Private Subnet
# -----------------------------------------------------------------------------
module "backend_ec2" {
  source = "../module/Backend_EC2"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  instance_type             = var.backend_instance_type
  private_subnet_id         = module.networking.private_subnet_ids[0]
  backend_security_group_id = module.security.ecs_security_group_id
  key_name                  = module.bastion.key_name
  backend_port              = var.backend_container_port

  # Database
  mysql_host     = module.database.db_address
  mysql_database = var.mysql_database
  mysql_user     = var.mysql_user
  mysql_password = var.mysql_password
  mysql_port     = module.database.db_port

  # S3
  s3_bucket_name = module.storage.bucket_id
  s3_bucket_arn  = module.storage.bucket_arn

  aspnetcore_environment = var.aspnetcore_environment
}

# -----------------------------------------------------------------------------
# ALB Target Group Attachment
# Gắn Backend EC2 vào ALB Target Group
# -----------------------------------------------------------------------------
resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = module.alb.backend_target_group_arn
  target_id        = module.backend_ec2.instance_id
  port             = var.backend_container_port
}

# -----------------------------------------------------------------------------
# AutoStart Lambda Module
# Tự động Start/Stop instances theo lịch và GitHub webhook
# -----------------------------------------------------------------------------
module "autostart" {
  source = "../module/AutoStart"

  project_name = var.project_name
  environment  = var.environment

  bastion_instance_id = module.bastion.instance_id
  nat_instance_id     = module.nat_instance.instance_id
  backend_instance_id = module.backend_ec2.instance_id
}
