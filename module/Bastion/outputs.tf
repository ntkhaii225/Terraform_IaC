# =============================================================================
# Bastion Module - Outputs
# =============================================================================

output "instance_id" {
  description = "Bastion EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Bastion public IP address"
  value       = aws_instance.bastion.public_ip
}

output "private_ip" {
  description = "Bastion private IP address"
  value       = aws_instance.bastion.private_ip
}

output "key_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.bastion.key_name
}
