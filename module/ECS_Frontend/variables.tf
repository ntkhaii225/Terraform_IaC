# =============================================================================
# ECS Frontend Cluster Module - Variables
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
variable "frontend_target_group_arn" {
  description = "Frontend Target Group ARN from ALB"
  type        = string
}

# --- ECS Configuration ---
variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH key name for EC2 instance"
  type        = string
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
  description = "CPU units for frontend container (1024 = 1 vCPU)"
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

# --- Environment Variables ---

