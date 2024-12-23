variable "frontend_repo_name" {
  type = string
}
variable "backend_rds_repo_name" {
  type = string
}
variable "backend_redis_repo_name" {
  type = string
}
variable "common_tags" {
  type = map(string)
}
