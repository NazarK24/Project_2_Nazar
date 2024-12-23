# outputs.tf
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = module.rds.rds_endpoint
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.redis.redis_endpoint
}
