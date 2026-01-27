# =============================================================================
# ECS Frontend Cluster Module - Outputs
# =============================================================================

# --- ECS Cluster Outputs ---
output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.frontend.id
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.frontend.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.frontend.arn
}

# --- ECS Service Outputs ---
output "service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.frontend.name
}

output "service_id" {
  description = "ECS Service ID"
  value       = aws_ecs_service.frontend.id
}

# --- EC2 Instance Outputs ---
output "instance_id" {
  description = "Frontend EC2 Instance ID"
  value       = aws_instance.ecs_frontend.id
}

output "instance_private_ip" {
  description = "Frontend EC2 Instance Private IP"
  value       = aws_instance.ecs_frontend.private_ip
}

# --- IAM Outputs ---
output "ecs_instance_role_arn" {
  description = "ECS Instance IAM Role ARN"
  value       = aws_iam_role.ecs_instance_role.arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

