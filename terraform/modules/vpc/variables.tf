variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidr" {
  type = string
}
variable "private_subnet_cidr_1" {
  type = string
}
variable "private_subnet_cidr_2" {
  type = string
}
variable "common_tags" {
  type = map(string)
}
