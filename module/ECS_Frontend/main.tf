# =============================================================================
# ECS Frontend Cluster Module - Main Resources
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster" "frontend" {
  name = "${var.project_name}-frontend-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name        = "${var.project_name}-frontend-cluster"
    Environment = var.environment
  }
}

# CloudWatch Log Group removed to reduce costs
# Logs can be viewed via docker logs on EC2 instance if needed

# # -----------------------------------------------------------------------------
# # IAM Role for ECS Instances (EC2)
# # Cho phép EC2 instances join vào ECS cluster
# # -----------------------------------------------------------------------------
# resource "aws_iam_role" "ecs_instance_role" {
#   name = "${var.project_name}-frontend-ecs-instance-role"
# 
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# 
#   tags = {
#     Name        = "${var.project_name}-frontend-ecs-instance-role"
#     Environment = var.environment
#   }
# }
# 
# # Attach AWS managed policy cho ECS instances
# resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }
# 
# # Instance Profile cho Launch Template
# resource "aws_iam_instance_profile" "ecs" {
#   name = "${var.project_name}-frontend-ecs-instance-profile"
#   role = aws_iam_role.ecs_instance_role.name
# 
#   tags = {
#     Name        = "${var.project_name}-frontend-ecs-instance-profile"
#     Environment = var.environment
#   }
# }

# -----------------------------------------------------------------------------
# IAM Role for ECS Task Execution
# Cho phép ECS pull images từ ECR và ghi logs vào CloudWatch
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-frontend-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-frontend-task-execution-role"
    Environment = var.environment
  }
}

# Attach AWS managed policy cho task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------------------------------
# IAM Role for ECS Tasks (Application)
# Role cho application code chạy trong container
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-frontend-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-frontend-task-role"
    Environment = var.environment
  }
}

# # -----------------------------------------------------------------------------
# # Data Source: ECS Optimized AMI
# # Lấy AMI mới nhất cho ECS on EC2
# # -----------------------------------------------------------------------------
# data "aws_ami" "ecs_optimized" {
#   most_recent = true
#   owners      = ["amazon"]
# 
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
#   }
# 
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }
# 
# # -----------------------------------------------------------------------------
# # Single EC2 Instance for ECS (No Auto Scaling)
# # -----------------------------------------------------------------------------
# resource "aws_instance" "ecs_frontend" {
#   ami                    = data.aws_ami.ecs_optimized.id
#   instance_type          = var.instance_type
#   subnet_id              = var.private_subnet_ids[0]
#   vpc_security_group_ids = [var.ecs_security_group_id]
#   iam_instance_profile   = aws_iam_instance_profile.ecs.name
#   key_name               = var.key_name
# 
#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${aws_ecs_cluster.frontend.name} >> /etc/ecs/ecs.config
#               echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
# 
#               # Enable Docker & ECS agent to start on boot
#               systemctl enable --now docker
#               systemctl enable --now ecs
#               EOF
#   )
# 
#   root_block_device {
#     volume_size           = 30
#     volume_type           = "gp3"
#     delete_on_termination = true
#     encrypted             = true
#   }
# 
#   tags = {
#     Name        = "${var.project_name}-frontend-ecs-instance"
#     Environment = var.environment
#   }
# 
#   lifecycle {
#     ignore_changes = [ami]
#   }
# }


# -----------------------------------------------------------------------------
# ECS Task Definition
# Định nghĩa container cho frontend
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "frontend" {
  family = "${var.project_name}-frontend"
  # network_mode             = "bridge"
  # requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${var.frontend_image}:${var.frontend_image_tag}"
      cpu       = var.frontend_cpu
      memory    = var.frontend_memory
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
        }
      ]

      environment = [

        {
          name  = "NODE_ENV"
          value = var.environment == "prod" ? "production" : "development"
        }
      ]

      # CloudWatch logs disabled to reduce costs
      # View logs via: docker logs <container_id> on EC2 instance

      # Health check is handled by ALB Target Group, not container health check
    }
  ])

  tags = {
    Name        = "${var.project_name}-frontend-task"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# ECS Service
# Quản lý và duy trì số lượng tasks mong muốn
# -----------------------------------------------------------------------------
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = aws_ecs_cluster.frontend.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  # launch_type     = "EC2"
  launch_type = "FARGATE"

  # Allow service to drop to 0 healthy tasks during deployment
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  # Placement strategy: Spread across AZs
  # ordered_placement_strategy {
  #   type  = "spread"
  #   field = "attribute:ecs.availability-zone"
  # }

  # Placement strategy: Spread across instances
  # ordered_placement_strategy {
  #   type  = "spread"
  #   field = "instanceId"
  # }

  # Đợi EC2 có instances trước khi deploy service
  #   depends_on = [
  #     aws_instance.ecs_frontend,
  #     aws_iam_role_policy_attachment.ecs_task_execution_role
  #   ]

  tags = {
    Name        = "${var.project_name}-frontend-service"
    Environment = var.environment
  }
}
