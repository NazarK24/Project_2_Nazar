resource "aws_security_group" "redis_sg" {
  name   = "redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "redis-sg" })
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "my-demo-redis-subnet-group"
  subnet_ids = var.private_subnets
  tags       = merge(var.common_tags, { Name = "my-demo-redis-subnet-group" })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "my-demo-redis"
  description          = "My Demo Redis"             # заміна replication_group_description
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t3.micro"

  # Коли хочемо 1 shard без реплік:
  num_node_groups         = 1        # 1 shard
  replicas_per_node_group = 0        # без реплік

  parameter_group_name    = "default.redis6.x"
  subnet_group_name       = aws_elasticache_subnet_group.this.name
  security_group_ids      = [aws_security_group.redis_sg.id]
  automatic_failover_enabled = false
  port                    = 6379

  # Якщо вам потрібен пароль (AUTH):
   auth_token = var.redis_password
   transit_encryption_enabled = true
   at_rest_encryption_enabled = true

  tags = merge(var.common_tags, { Name = "my-demo-redis" })
}