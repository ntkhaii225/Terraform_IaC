# =============================================================================
# Backend EC2 Module - Variables
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

# --- Compute ---
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "private_subnet_id" {
  description = "Private Subnet ID to place the Backend EC2"
  type        = string
}

variable "backend_security_group_id" {
  description = "Security Group ID for Backend EC2"
  type        = string
}

variable "key_name" {
  description = "SSH key name (from Bastion module)"
  type        = string
}

# --- Application ---
variable "backend_port" {
  description = "Port the backend app listens on"
  type        = number
  default     = 8080
}

variable "aspnetcore_environment" {
  description = "ASP.NET Core environment"
  type        = string
  default     = "Development"
}

# --- Database ---
variable "mysql_host" {
  description = "MySQL host (RDS endpoint)"
  type        = string
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
}

variable "mysql_user" {
  description = "MySQL username"
  type        = string
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

# --- S3 ---
variable "s3_bucket_name" {
  description = "S3 bucket name for application storage"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for application storage"
  type        = string
}

variable "s3_artifact_bucket_arn" {
  description = "S3 bucket ARN for deployment artifacts"
  type        = string
  default     = "arn:aws:s3:::*" # Will be refined when CI/CD is set up
}
