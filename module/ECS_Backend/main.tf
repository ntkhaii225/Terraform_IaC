# =============================================================================
# ECS Backend Cluster Module - Main Resources
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster" "backend" {
  name = "${var.project_name}-backend-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name        = "${var.project_name}-backend-cluster"
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
#   name = "${var.project_name}-backend-ecs-instance-role"
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
#     Name        = "${var.project_name}-backend-ecs-instance-role"
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
#   name = "${var.project_name}-backend-ecs-instance-profile"
#   role = aws_iam_role.ecs_instance_role.name
# 
#   tags = {
#     Name        = "${var.project_name}-backend-ecs-instance-profile"
#     Environment = var.environment
#   }
# }

# -----------------------------------------------------------------------------
# IAM Role for ECS Task Execution
# Cho phép ECS pull images từ ECR và ghi logs vào CloudWatch
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-backend-task-execution-role"

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
    Name        = "${var.project_name}-backend-task-execution-role"
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
  name = "${var.project_name}-backend-task-role"

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
    Name        = "${var.project_name}-backend-task-role"
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
# # Cost-effective solution for dev/staging environments
# # -----------------------------------------------------------------------------
# resource "aws_instance" "ecs_backend" {
#   ami                    = data.aws_ami.ecs_optimized.id
#   instance_type          = var.instance_type
#   subnet_id              = var.private_subnet_ids[0] # Use first private subnet
#   vpc_security_group_ids = [var.ecs_security_group_id]
#   iam_instance_profile   = aws_iam_instance_profile.ecs.name
#   key_name               = var.key_name # SSH key for access from Bastion
# 
#   # User data to join ECS cluster and deploy MySQL/Redis
#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               set -e
#               
#               # Join ECS Cluster
#               echo ECS_CLUSTER=${aws_ecs_cluster.backend.name} >> /etc/ecs/ecs.config
#               echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
#               
#               # Enable Docker & ECS agent to start on boot
#               systemctl enable --now docker
#               systemctl enable --now ecs
#               
#               # Log success
#               echo "ECS Configuration Complete" >> /var/log/user-data.log
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
#     Name        = "${var.project_name}-backend-ecs-instance"
#     Environment = var.environment
#   }
# 
#   lifecycle {
#     ignore_changes = [ami]
#   }
# }

# -----------------------------------------------------------------------------
# ECS Task Definition
# Định nghĩa container cho backend
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend" {
  family = "${var.project_name}-backend"
  # network_mode             = "bridge"
  # requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.backend_image}:${var.backend_image_tag}"
      cpu       = var.backend_cpu
      memory    = var.backend_memory
      essential = true

      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]



      environment = [
        {
          name  = "MYSQL_HOST"
          value = var.mysql_host
        },
        {
          name  = "MYSQL_DATABASE"
          value = var.mysql_database
        },
        {
          name  = "MYSQL_USER"
          value = var.mysql_user
        },
        {
          name  = "MYSQL_PASSWORD"
          value = var.mysql_password
        },
        {
          name  = "MYSQL_PORT"
          value = tostring(var.mysql_port)
        },

        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = var.aspnetcore_environment
        },
        {
          name  = "BACKEND_PORT"
          value = tostring(var.backend_container_port)
        },
        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:${var.backend_container_port}"
        },
        {
          # Override appsettings.json connection string via environment variable
          name  = "ConnectionStrings__DefaultConnection"
          value = "Server=${var.mysql_host};Port=${var.mysql_port};Database=${var.mysql_database};User=${var.mysql_user};Password=${var.mysql_password};"
        },
        {
          name  = "AWS__S3__BucketName"
          value = var.s3_bucket_name
        },
        {
          name  = "AWS__Region"
          value = var.aws_region
        }
      ]

      # CloudWatch logs disabled to reduce costs
      # View logs via: docker logs <container_id> on EC2 instance

      # Health check is handled by ALB Target Group, not container health check
      # Container image doesn't have curl/wget installed
    }
  ])

  tags = {
    Name        = "${var.project_name}-backend-task"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# ECS Service
# Quản lý và duy trì số lượng tasks mong muốn
# -----------------------------------------------------------------------------
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  # launch_type     = "EC2"
  launch_type = "FARGATE"

  # Allow service to drop to 0 healthy tasks during deployment
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = var.backend_container_port
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

  tags = {
    Name        = "${var.project_name}-backend-service"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# IAM Policy for S3 Access
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-backend-s3-policy"
  description = "Allow backend task to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}
