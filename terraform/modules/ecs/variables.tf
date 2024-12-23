variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "frontend_image_url" {
  type = string
}
variable "backend_rds_image_url" {
  type = string
}
variable "backend_redis_image_url" {
  type = string
}

variable "db_name" {
  type = string
}
variable "db_user" {
  type = string
}
variable "db_password" {
  type = string
}
variable "redis_password" {
  type = string
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "common_tags" {
  type = map(string)
}
