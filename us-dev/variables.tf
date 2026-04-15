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
  default     = "t3.small"
}

variable "bastion_public_key" {
  description = "SSH public key for Bastion access"
  type        = string
}

# --- Backend EC2 Configuration ---
variable "backend_instance_type" {
  description = "EC2 instance type for Backend"
  type        = string
  default     = "t3.small"
}

variable "backend_container_port" {
  description = "Port for backend application"
  type        = number
  default     = 8080
}

# --- Database Configuration ---
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
  description = "Domain name for the application"
  type        = string
  default     = "fuec.site"
}
