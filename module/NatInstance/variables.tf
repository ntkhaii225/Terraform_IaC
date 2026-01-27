variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  description = "Subnet to deploy NAT Instance (Public)"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of Private Subnet CIDRs to allow traffic from"
  type        = list(string)
}

variable "bastion_security_group_id" {
  description = "Security Group ID of Bastion for SSH access"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}
