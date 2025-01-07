#############################
# ECS Cluster
#############################
resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
  tags = merge(var.common_tags, { Name = var.ecs_cluster_name })
}

#############################
# Security Group for ECS tasks
#############################
resource "aws_security_group" "ecs_sg" {
  name   = "${var.ecs_cluster_name}-sg"
  vpc_id = var.vpc_id
  tags = merge(var.common_tags, { Name = "${var.ecs_cluster_name}-sg" })
}

resource "aws_security_group_rule" "allow_alb_to_ecs_ingress" {
  security_group_id        = aws_security_group.ecs_sg.id
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = var.alb_sg_id
  description              = "Allow ALB access on port 8000"
}

#############################
# IAM Role for ECS EC2
#############################
data "aws_iam_policy_document" "ecs_instance_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecsInstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume.json
  tags               = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

#############################
# Launch Configuration
#############################
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-lt-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.ecs_instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
  user_data = filebase64("${path.module}/ecs_user_data.sh")


  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, { Name = "ecs-instance" })
  }

  lifecycle {
    create_before_destroy = true
  }
}


#############################
# Auto Scaling Group
#############################
resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "ecs-asg"
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }
  min_size             = 1
  max_size             = 3  # Збільшено максимальний розмір для кращої масштабованості
  desired_capacity     = 2
  vpc_zone_identifier  = var.private_subnets 

  tag {
    key                 = "Name"
    value               = "ecs-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
}

#############################
# ECS Task Definitions
#############################
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = 256
  memory                   = 512

  container_definitions = templatefile(
    "${path.module}/templates/frontend_container.json",
    {
      FRONTEND_IMAGE_URL = var.frontend_image_url
      DB_NAME            = var.db_name
      DB_USER            = var.db_user
      DB_PASSWORD        = var.db_password
      REDIS_PASSWORD     = var.redis_password
      CONTAINER_PORT     = var.frontend_container_port
    }
  )
}

resource "aws_ecs_task_definition" "backend_rds_task" {
  family                   = "backend-rds-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = 256
  memory                   = 512

  container_definitions = templatefile(
    "${path.module}/templates/backend_rds_container.json",
    {
      BACKEND_RDS_IMAGE_URL = var.backend_rds_image_url
      DB_NAME               = var.db_name
      DB_USER               = var.db_user
      DB_PASSWORD           = var.db_password
      CONTAINER_PORT        = var.backend_rds_container_port
    }
  )
}

resource "aws_ecs_task_definition" "backend_redis_task" {
  family                   = "backend-redis-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = 256
  memory                   = 512

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
  launch_type     = "EC2"
  desired_count   = var.frontend_desired_count
  task_definition = aws_ecs_task_definition.frontend_task.arn

  # Optional ALB Configuration
  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  depends_on = [
    var.frontend_listener_arn
  ]
}

resource "aws_ecs_service" "backend_rds_service" {
  name            = "backend-rds-service"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "EC2"
  desired_count   = var.backend_rds_desired_count
  task_definition = aws_ecs_task_definition.backend_rds_task.arn
}

resource "aws_ecs_service" "backend_redis_service" {
  name            = "backend-redis-service"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "EC2"
  desired_count   = var.backend_redis_desired_count
  task_definition = aws_ecs_task_definition.backend_redis_task.arn
}
