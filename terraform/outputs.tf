output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = module.rds.rds_endpoint
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.redis.redis_endpoint
}
