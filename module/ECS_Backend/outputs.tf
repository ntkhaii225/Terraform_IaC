# =============================================================================
# ECS Backend Cluster Module - Outputs
# =============================================================================

# --- ECS Cluster Outputs ---
output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.backend.id
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.backend.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.backend.arn
}

# --- ECS Service Outputs ---
output "service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.backend.name
}

output "service_id" {
  description = "ECS Service ID"
  value       = aws_ecs_service.backend.id
}

# --- EC2 Instance Outputs ---
# output "ecs_instance_id" {
#   description = "ECS EC2 Instance ID"
#   value       = aws_instance.ecs_backend.id
# }
# 
# output "ecs_instance_private_ip" {
#   description = "ECS EC2 Instance Private IP"
#   value       = aws_instance.ecs_backend.private_ip
# }
# 
# --- IAM Outputs ---
# output "ecs_instance_role_arn" {
#   description = "ECS Instance IAM Role ARN"
#   value       = aws_iam_role.ecs_instance_role.arn
# }
# 
output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

