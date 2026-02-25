# =============================================================================
# Application Load Balancer Module
# =============================================================================

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Target Group - Frontend (Port 3000)
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "frontend" {
  name                 = "${var.project_name}-frontend-tg"
  port                 = 3000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip" # For Fargate awsvpc network mode
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    path                = var.frontend_health_check_path
    port                = 3000
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  tags = {
    Name        = "${var.project_name}-frontend-tg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Target Group - Backend (Port 5000)
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "backend" {
  name                 = "${var.project_name}-backend-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip" # For Fargate awsvpc network mode
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    path                = var.backend_health_check_path
    port                = 8080
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  tags = {
    Name        = "${var.project_name}-backend-tg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Listener - HTTP 80
# Default: Forward đến Frontend
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# -----------------------------------------------------------------------------
# Listener Rule - Route /api/* đến Backend
# -----------------------------------------------------------------------------
resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-backend-rule"
  }
}
