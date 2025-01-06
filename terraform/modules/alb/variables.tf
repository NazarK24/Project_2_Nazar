variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "frontend_container_port" {
  type    = number
  default = 80
}

variable "common_tags" {
  type = map(string)
}