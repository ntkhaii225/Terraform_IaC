# =============================================================================
# ECS Backend Cluster Module - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# --- VPC & Networking ---
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS instances"
  type        = list(string)
}

# --- Security Groups ---
variable "ecs_security_group_id" {
  description = "Security Group ID for ECS instances"
  type        = string
}

# --- Load Balancer ---
variable "backend_target_group_arn" {
  description = "Backend Target Group ARN from ALB"
  type        = string
}

# --- ECS Configuration ---
variable "key_name" {
  description = "SSH key pair name for EC2 instance access"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.small"
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 2
}

# --- Container Configuration ---
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
  description = "CPU units for backend container (1024 = 1 vCPU)"
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

# --- Environment Variables from .env ---
variable "mysql_host" {
  description = "MySQL database host"
  type        = string
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

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for storage"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks"
  type        = number
  default     = 60
}
