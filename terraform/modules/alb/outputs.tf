output "alb_dns_name" {
  value = aws_lb.frontend_alb.dns_name
}

output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend_target_group.arn
}

output "frontend_listener_arn" {
  value = aws_lb_listener.frontend_listener.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "backend_rds_target_group_arn" {
  value = aws_lb_target_group.backend_rds_target_group.arn
}

output "backend_redis_target_group_arn" {
  value = aws_lb_target_group.backend_redis_target_group.arn
}
