# =============================================================================
# Backend EC2 Module - Outputs
# =============================================================================

output "instance_id" {
  description = "Backend EC2 Instance ID"
  value       = aws_instance.backend.id
}

output "private_ip" {
  description = "Backend EC2 Private IP"
  value       = aws_instance.backend.private_ip
}
