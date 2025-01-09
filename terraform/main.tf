# main.tf

############
# VPC
############
module "vpc" {
  source                  = "./modules/vpc"
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr_1    = var.public_subnet_cidr_1
  public_subnet_cidr_2    = var.public_subnet_cidr_2
  private_subnet_cidr_1   = var.private_subnet_cidr_1
  private_subnet_cidr_2   = var.private_subnet_cidr_2  
  common_tags             = var.common_tags
}

############
# ECR
############
module "ecr" {
  source      = "./modules/ecr"
  common_tags = var.common_tags

  # Передаємо назви сховищ
  frontend_repo_name      = "my-demo-frontend"
  backend_rds_repo_name   = "my-demo-backend-rds"
  backend_redis_repo_name = "my-demo-backend-redis"
  
  # Додаємо теги для образів
  frontend_image_tag      = var.frontend_image_tag
  backend_rds_image_tag   = var.backend_rds_image_tag
  backend_redis_image_tag = var.backend_redis_image_tag
}

############
# ECS
############
module "ecs" {
  source = "./modules/ecs"

  # Базові налаштування
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  ecs_cluster_name = "my-demo-ecs-cluster"
  common_tags      = var.common_tags
  
  # ALB налаштування
  alb_sg_id               = module.alb.alb_sg_id
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  frontend_listener_arn     = module.alb.frontend_listener_arn
  backend_rds_target_group_arn = module.alb.backend_rds_target_group_arn
  backend_redis_target_group_arn = module.alb.backend_redis_target_group_arn

  # Container налаштування
  frontend_container_port = var.frontend_container_port
  frontend_image_url      = "${module.ecr.frontend_repo_url}:${var.frontend_image_tag}"
  backend_rds_image_url   = "${module.ecr.backend_rds_repo_url}:${var.backend_rds_image_tag}"
  backend_redis_image_url = "${module.ecr.backend_redis_repo_url}:${var.backend_redis_image_tag}"

  # Database налаштування
  db_host       = module.rds.rds_endpoint
  db_name       = var.db_name
  db_user       = var.db_username
  db_password   = var.db_password
  
  # Redis налаштування
  redis_host     = module.redis.redis_endpoint
  redis_password = var.redis_password

  # Security Groups
  rds_sg_id   = module.rds.rds_sg_id
  redis_sg_id = module.redis.redis_sg_id
}

############
# ALB
############
module "alb" {
  source           = "./modules/alb"
  vpc_id           = module.vpc.vpc_id 
  public_subnets   = module.vpc.public_subnets
  frontend_container_port = var.frontend_container_port 
  common_tags      = var.common_tags
}


############
# RDS
############
module "rds" {
  source               = "./modules/rds"
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
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
  private_subnets    = module.vpc.private_subnets
  redis_password     = var.redis_password
  common_tags        = var.common_tags
  ecs_sg_id          = module.ecs.ecs_sg_id
}