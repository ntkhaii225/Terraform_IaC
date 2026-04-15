# =============================================================================
# Frontend S3 + CloudFront Module - Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name (e.g. fuec.site)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN (must be in us-east-1 for CloudFront)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name (e.g. fuec-alb-xxx.us-east-1.elb.amazonaws.com)"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB Hosted Zone ID (for Route53 alias)"
  type        = string
}

variable "alb_domain_name" {
  description = "Custom domain name for ALB origin (e.g. alb.fuec.site)"
  type        = string
}
