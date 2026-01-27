# =============================================================================
# Outputs for ALB Module
# =============================================================================

output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name - URL để truy cập ứng dụng"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID (for Route53)"
  value       = aws_lb.main.zone_id
}

output "frontend_target_group_arn" {
  description = "Frontend Target Group ARN - dùng cho ECS Service"
  value       = aws_lb_target_group.frontend.arn
}

output "backend_target_group_arn" {
  description = "Backend Target Group ARN - dùng cho ECS Service"
  value       = aws_lb_target_group.backend.arn
}

output "http_listener_arn" {
  description = "HTTP Listener ARN"
  value       = aws_lb_listener.http.arn
}
