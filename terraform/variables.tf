# variables.tf

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project     = "my-demo"
    Environment = "dev"
  }
}

variable "db_name" {
  type    = string
  default = "postgres"
}

variable "db_username" {
  type    = string
  default = "mypostgres"
}

variable "db_password" {
  type    = string
  default = "mypassword1"
}

variable "redis_password" {
  type    = string
  default = "mypassword1"
}