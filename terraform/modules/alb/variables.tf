variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "frontend_container_port" {
  type    = number
  default = 8000
}

variable "common_tags" {
  type = map(string)
}