variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "redis_password" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}