# main.tf

############
# VPC
############
module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  common_tags         = var.common_tags
}

############
# ECR
############
module "ecr" {
  source      = "./modules/ecr"
  common_tags = var.common_tags

  # Наприклад, передаємо назви сховищ
  frontend_repo_name      = "my-demo-frontend"
  backend_rds_repo_name   = "my-demo-backend-rds"
  backend_redis_repo_name = "my-demo-backend-redis"
}

############
# ECS
############
module "ecs" {
  source = "./modules/ecs"

  vpc_id                   = module.vpc.vpc_id
  private_subnet_id        = module.vpc.private_subnet_id
  ecs_cluster_name         = "my-demo-ecs-cluster"
  ecs_instance_type        = "t2.micro"         # free-tier
  container_port           = 8000
  common_tags              = var.common_tags

  # Передаємо посилання на ECR, щоб ECS task definitions посилалися на образи
  frontend_image_url       = module.ecr.frontend_repo_url
  backend_rds_image_url    = module.ecr.backend_rds_repo_url
  backend_redis_image_url  = module.ecr.backend_redis_repo_url

  db_name                  = var.db_name
  db_user                  = var.db_username
  db_password              = var.db_password
  redis_password           = var.redis_password
}

############
# ALB
############
module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_id
  alb_name       = "my-demo-alb"
  container_port = 8000
  ecs_sg_id      = module.ecs.ecs_sg_id
  common_tags    = var.common_tags
}

############
# RDS
############
module "rds" {
  source               = "./modules/rds"
  vpc_id               = module.vpc.vpc_id
  private_subnet_id    = module.vpc.private_subnet_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  common_tags          = var.common_tags
  ecs_sg_id            = module.ecs.ecs_sg_id
}

############
# Redis
############
module "redis" {
  source             = "./modules/redis"
  vpc_id             = module.vpc.vpc_id
  private_subnet_id  = module.vpc.private_subnet_id
  redis_password     = var.redis_password
  common_tags        = var.common_tags
  ecs_sg_id          = module.ecs.ecs_sg_id
}