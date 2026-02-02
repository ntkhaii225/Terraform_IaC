# =============================================================================
# Variables for Security Module
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH to Bastion Host (e.g., your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
