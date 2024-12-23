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
  subnet_ids = [var.private_subnet_id]
  tags       = merge(var.common_tags, { Name = "my-demo-redis-subnet-group" })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "my-demo-redis"
  replication_group_description = "My Demo Redis"
  engine                        = "redis"
  engine_version                = "6.x"
  node_type                     = "cache.t2.micro"
  number_cache_clusters         = 1
  parameter_group_name          = "default.redis6.x"
  subnet_group_name             = aws_elasticache_subnet_group.this.name
  security_group_ids            = [aws_security_group.redis_sg.id]
  automatic_failover_enabled    = false
  port                          = 6379

  # Зверніть увагу: налаштування пароля для Redis
  # Якщо хочете AUTH:
  #   auth_token = var.redis_password
  #   transit_encryption_enabled = true
  #   at_rest_encryption_enabled = true
  #   (але тоді потрібен cluster mode = redis 6.0+)
  #   Для local free-tier тренувань часто роблять без шифрування, без пароля.

  tags = merge(var.common_tags, { Name = "my-demo-redis" })
}
