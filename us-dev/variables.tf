# =============================================================================
# Root Module - Variable Definitions
# =============================================================================

# --- Project Configuration ---
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

# --- Networking Configuration ---
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
}

variable "public_subnet_cidr_2" {
  description = "CIDR block for public subnet 2"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
}

variable "private_subnet_cidr_2" {
  description = "CIDR block for private subnet 2"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for subnet 1"
  type        = string
}

variable "availability_zone_2" {
  description = "Availability zone for subnet 2"
  type        = string
}

# --- Bastion Configuration ---
variable "bastion_instance_type" {
  description = "EC2 instance type for Bastion"
  type        = string
  default     = "t2.micro"
}

variable "bastion_public_key" {
  description = "SSH public key for Bastion access"
  type        = string
}

# --- Frontend ECS Configuration ---
variable "frontend_instance_type" {
  description = "EC2 instance type for Frontend ECS cluster"
  type        = string
  default     = "t3.small"
}

variable "frontend_asg_min_size" {
  description = "Minimum number of EC2 instances for Frontend"
  type        = number
  default     = 1
}

variable "frontend_asg_max_size" {
  description = "Maximum number of EC2 instances for Frontend"
  type        = number
  default     = 3
}

variable "frontend_asg_desired_capacity" {
  description = "Desired number of EC2 instances for Frontend"
  type        = number
  default     = 2
}

variable "frontend_image" {
  description = "Docker image for frontend container"
  type        = string
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "frontend_container_port" {
  description = "Container port for frontend"
  type        = number
  default     = 3000
}

variable "frontend_cpu" {
  description = "CPU units for frontend container"
  type        = number
  default     = 512
}

variable "frontend_memory" {
  description = "Memory (MB) for frontend container"
  type        = number
  default     = 1024
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 2
}

variable "clerk_publishable_key" {
  description = "Clerk publishable key for frontend"
  type        = string
  sensitive   = true
}

# --- Backend ECS Configuration ---
variable "backend_instance_type" {
  description = "EC2 instance type for Backend ECS cluster"
  type        = string
  default     = "t3.small"
}

variable "backend_asg_min_size" {
  description = "Minimum number of EC2 instances for Backend"
  type        = number
  default     = 1
}

variable "backend_asg_max_size" {
  description = "Maximum number of EC2 instances for Backend"
  type        = number
  default     = 3
}

variable "backend_asg_desired_capacity" {
  description = "Desired number of EC2 instances for Backend"
  type        = number
  default     = 2
}

variable "backend_image" {
  description = "Docker image for backend container"
  type        = string
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "backend_container_port" {
  description = "Container port for backend"
  type        = number
  default     = 8080
}

variable "backend_cpu" {
  description = "CPU units for backend container"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory (MB) for backend container"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 2
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "fuec"
}

variable "mysql_user" {
  description = "MySQL user"
  type        = string
  default     = "sa"
}

variable "mysql_password" {
  description = "MySQL password"
  type        = string
  sensitive   = true
}

variable "mysql_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "aspnetcore_environment" {
  description = "ASP.NET Core environment"
  type        = string
  default     = "Development"
}

variable "domain_name" {
  description = "Domain name for ACM certificate"
  type        = string
  default     = "fuec.site"
}
