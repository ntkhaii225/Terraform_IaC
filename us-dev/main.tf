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
# Creates Security Groups for ALB, ECS, Bastion
# -----------------------------------------------------------------------------
module "security" {
  source = "../module/Security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}

# -----------------------------------------------------------------------------
# Application Load Balancer Module
# Creates ALB, Target Groups, Listeners
# -----------------------------------------------------------------------------
module "alb" {
  source = "../module/ALB"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

# -----------------------------------------------------------------------------
# Bastion Host Module (Optional)
# Creates EC2 instance for SSH access to private resources
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
# NAT Instance Module (Cost-effective NAT)
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
# ECS Frontend Cluster Module
# Creates ECS cluster, ASG, Task Definition, Service for Frontend
# -----------------------------------------------------------------------------
module "ecs_frontend" {
  source = "../module/ECS_Frontend"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Networking
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.security.ecs_security_group_id

  # Load Balancer
  frontend_target_group_arn = module.alb.frontend_target_group_arn

  # EC2 Configuration
  instance_type        = var.frontend_instance_type
  asg_min_size         = var.frontend_asg_min_size
  asg_max_size         = var.frontend_asg_max_size
  asg_desired_capacity = var.frontend_asg_desired_capacity
  key_name             = module.bastion.key_name

  # Container Configuration
  frontend_image          = var.frontend_image
  frontend_image_tag      = var.frontend_image_tag
  frontend_container_port = var.frontend_container_port
  frontend_cpu            = var.frontend_cpu
  frontend_memory         = var.frontend_memory
  frontend_desired_count  = var.frontend_desired_count

  # Environment Variables

}

# -----------------------------------------------------------------------------
# ECS Backend Cluster Module
# Creates ECS cluster, ASG, Task Definition, Service for Backend
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Database Module
# Creates RDS MySQL instance
# -----------------------------------------------------------------------------
module "database" {
  source = "../module/Database"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  # Deploy to private subnets
  private_subnet_ids = module.networking.private_subnet_ids

  # Security Groups
  ecs_security_group_id     = module.security.ecs_security_group_id
  bastion_security_group_id = module.security.bastion_security_group_id

  # Database Config
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
# Storage Module (S3)
# -----------------------------------------------------------------------------
module "storage" {
  source = "../module/Storage"

  bucket_name = "${var.project_name}-storage-${var.environment}-${random_string.suffix.result}"
  environment = var.environment
}

# -----------------------------------------------------------------------------
# ECS Backend Cluster Module
# Creates ECS cluster, ASG, Task Definition, Service for Backend
# -----------------------------------------------------------------------------
module "ecs_backend" {
  source = "../module/ECS_Backend"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Networking
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.security.ecs_security_group_id

  # Load Balancer
  backend_target_group_arn = module.alb.backend_target_group_arn

  # EC2 Configuration
  key_name             = module.bastion.key_name # Use Bastion SSH key
  instance_type        = var.backend_instance_type
  asg_min_size         = var.backend_asg_min_size
  asg_max_size         = var.backend_asg_max_size
  asg_desired_capacity = var.backend_asg_desired_capacity

  # Container Configuration
  backend_image          = var.backend_image
  backend_image_tag      = var.backend_image_tag
  backend_container_port = var.backend_container_port
  backend_cpu            = var.backend_cpu
  backend_memory         = var.backend_memory
  backend_desired_count  = var.backend_desired_count

  # Database Configuration
  mysql_host     = module.database.db_address
  mysql_database = var.mysql_database
  mysql_user     = var.mysql_user
  mysql_password = var.mysql_password
  mysql_port     = module.database.db_port

  s3_bucket_arn  = module.storage.bucket_arn
  s3_bucket_name = module.storage.bucket_id

  aspnetcore_environment = var.aspnetcore_environment
}

# -----------------------------------------------------------------------------
# AutoStart Lambda Module
# Automatically starts instances on push to develop
# -----------------------------------------------------------------------------
module "autostart" {
  source = "../module/AutoStart"

  project_name = var.project_name
  environment  = var.environment

  bastion_instance_id = module.bastion.instance_id
  nat_instance_id     = module.nat_instance.instance_id
  # frontend_instance_id = module.ecs_frontend.instance_id
  # backend_instance_id  = module.ecs_backend.ecs_instance_id
  frontend_cluster_name = module.ecs_frontend.cluster_name
  frontend_service_name = module.ecs_frontend.service_name
  backend_cluster_name  = module.ecs_backend.cluster_name
  backend_service_name  = module.ecs_backend.service_name
}
