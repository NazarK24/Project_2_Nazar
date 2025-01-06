variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_instance_type" {
  type    = string
  default = "t2.micro"
}

# Frontend Variables
variable "frontend_image_url" {
  type = string
}

variable "frontend_container_port" {
  type    = number
  default = 8000
}

variable "frontend_desired_count" {
  default = 1
}

# Backend RDS Variables
variable "backend_rds_image_url" {
  type = string
}

variable "backend_rds_container_port" {
  type    = number
  default = 8001
}

variable "backend_rds_desired_count" {
  default = 1
}

# Backend Redis Variables
variable "backend_redis_image_url" {
  type = string
}

variable "backend_redis_container_port" {
  type    = number
  default = 8002
}

variable "backend_redis_desired_count" {
  default = 1
}

# Database Variables
variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

# Redis Variables
variable "redis_password" {
  type = string
}

# Tags
variable "common_tags" {
  type = map(string)
}
