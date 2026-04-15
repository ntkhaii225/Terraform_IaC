variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "backend_health_check_path" {
  description = "Health check path for Backend"
  type        = string
  default     = "/api/health"
}

variable "domain_name" {
  description = "Domain name for ACM certificate (e.g. fuec.site)"
  type        = string
}
