variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "ecs_sg_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
