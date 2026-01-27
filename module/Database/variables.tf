variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security Group ID of ECS Backend"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security Group ID of Bastion Host"
  type        = string
}

variable "db_name" {
  description = "Database Name"
  type        = string
}

variable "db_username" {
  description = "Database Master Username"
  type        = string
}

variable "db_password" {
  description = "Database Master Password"
  type        = string
  sensitive   = true
}
