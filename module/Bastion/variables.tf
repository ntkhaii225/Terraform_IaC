# =============================================================================
# Variables for Bastion Module
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID where Bastion will be deployed"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security Group ID for Bastion Host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Bastion"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "SSH public key for Bastion access"
  type        = string
}

