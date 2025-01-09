output "redis_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_sg_id" {
  value = aws_security_group.redis_sg.id
}