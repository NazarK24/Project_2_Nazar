#############################
# ECS Cluster
#############################
resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, { Name = var.ecs_cluster_name })
}

#############################
# Security Group for ECS tasks
#############################
resource "aws_security_group" "ecs_sg" {
  name   = "${var.ecs_cluster_name}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    from_port       = 8002
    to_port         = 8002
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.ecs_cluster_name}-sg" })
}

# Додаємо окремі правила після створення всіх security groups
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = var.rds_sg_id
}

resource "aws_security_group_rule" "ecs_to_redis" {
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = var.redis_sg_id
}

#############################
# ECS Task Definitions
#############################
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = templatefile(
    "${path.module}/templates/frontend_container.json",
    {
      FRONTEND_IMAGE_URL = var.frontend_image_url
      DB_HOST           = var.db_host
      DB_NAME           = var.db_name
      DB_USER           = var.db_user
      DB_PASSWORD       = var.db_password
      REDIS_HOST        = var.redis_host
      REDIS_PASSWORD    = var.redis_password
    }
  )
}

resource "aws_ecs_task_definition" "backend_rds_task" {
  family                   = "backend-rds-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = templatefile(
    "${path.module}/templates/backend_rds_container.json",
    {
      BACKEND_RDS_IMAGE_URL = var.backend_rds_image_url
      DB_NAME               = var.db_name
      DB_USER               = var.db_user
      DB_PASSWORD           = var.db_password
      DB_HOST              = var.db_host
      AWS_REGION           = "eu-north-1"
    }
  )
}

resource "aws_ecs_task_definition" "backend_redis_task" {
  family                   = "backend-redis-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = templatefile(
    "${path.module}/templates/backend_redis_container.json",
    {
      BACKEND_REDIS_IMAGE_URL = var.backend_redis_image_url
      REDIS_PASSWORD          = var.redis_password
      CONTAINER_PORT          = var.backend_redis_container_port
    }
  )
}


#############################
# ECS Services (приклад один)
#############################
resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }
}

resource "aws_ecs_service" "backend_rds_service" {
  name            = "backend-rds-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend_rds_task.arn
  desired_count   = var.backend_rds_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_rds_target_group_arn
    container_name   = "backend-rds"
    container_port   = var.backend_rds_container_port
  }
}

resource "aws_ecs_service" "backend_redis_service" {
  name            = "backend-redis-service"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.backend_redis_task.arn
  desired_count   = var.backend_redis_desired_count

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_redis_target_group_arn
    container_name   = "backend-redis"
    container_port   = var.backend_redis_container_port
  }
}

#############################
# IAM Role for CI/CD
#############################
resource "aws_iam_role" "cicd_role" {
  name = "cicd-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cicd_policy" {
  name = "cicd-ecs-policy"
  role = aws_iam_role.cicd_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

#############################
# IAM Role for Fargate
#############################
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "backend_rds" {
  name              = "/ecs/backend-rds"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "backend_redis" {
  name              = "/ecs/backend-redis"
  retention_in_days = 14
  tags              = var.common_tags
}
