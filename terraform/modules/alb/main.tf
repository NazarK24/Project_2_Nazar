resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  tags = merge(var.common_tags, { Name = "frontend-alb" })
}

resource "aws_lb_target_group" "frontend_target_group" {
  name        = "frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  tags = merge(var.common_tags, { Name = "frontend-tg" })
}

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  ingress = [
    {
      description = "Allow HTTP traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = merge(var.common_tags, { Name = "alb-sg" })
}
