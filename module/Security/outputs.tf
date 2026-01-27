# =============================================================================
# Outputs for Security Module
# =============================================================================

output "alb_security_group_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security Group ID for ECS"
  value       = aws_security_group.ecs.id
}

output "bastion_security_group_id" {
  description = "Security Group ID for Bastion Host"
  value       = aws_security_group.bastion.id
}
