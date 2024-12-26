variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
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