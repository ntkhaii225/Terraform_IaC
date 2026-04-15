variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "bastion_instance_id" {
  description = "The ID of the Bastion EC2 instance"
  type        = string
}

variable "nat_instance_id" {
  description = "The ID of the NAT EC2 instance"
  type        = string
}

variable "backend_instance_id" {
  description = "The ID of the Backend EC2 instance"
  type        = string
}
