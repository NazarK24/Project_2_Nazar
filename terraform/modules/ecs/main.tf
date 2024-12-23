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

  # ingress, egress додамо за потреби...
  # Ми зазвичай дозволимо inbound з ALB і outbound - будь-куди в VPC.

  tags = merge(var.common_tags, { Name = "${var.ecs_cluster_name}-sg" })
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

resource "aws_launch_configuration" "ecs_lc" {
  name_prefix          = "ecs-lc-"
  image_id             = data.aws_ami.ecs_optimized.id
  instance_type        = var.ecs_instance_type
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups      = [aws_security_group.ecs_sg.id]
  user_data            = file("${path.module}/../ecs_user_data.sh")
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, { Name = "ecs-lc" })
}

#############################
# Auto Scaling Group
#############################
resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "ecs-asg"
  launch_configuration = aws_launch_configuration.ecs_lc.name
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = [var.private_subnet_id]

  tag {
    key                 = "Name"
    value               = "ecs-asg"
    propagate_at_launch = true
  }

  tags = merge(var.common_tags, { Name = "ecs-asg" })
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
      CONTAINER_PORT     = var.container_port
    }
  )
}

# Аналогічно backend_rds_task, backend_redis_task...

#############################
# ECS Services (приклад один)
#############################
resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "EC2"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.frontend_task.arn
  # ALB та TargetGroups можна описати або в цьому модулі, або в ALB-модулі...
}