#------------------------------------------------------------------------------
# PROD Environment – Root Configuration
# Identical module wiring to dev; different variable values in prod.tfvars
# ensure HA (Multi-AZ RDS, 2 ECS replicas, deletion protection, longer logs).
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
  })
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix             = local.name_prefix
  cidr_block              = var.cidr_block
  public_subnets          = var.public_subnets
  private_backend_subnets = var.private_backend_subnets
  private_db_subnets      = var.private_db_subnets
  tags                    = local.common_tags
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  domain_name       = var.domain_name
  tags              = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix           = local.name_prefix
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  rds_sg_id             = module.security_groups.rds_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  multi_az              = var.db_multi_az
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
  tags                  = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix                        = local.name_prefix
  rds_credentials_secret_version_arn = module.rds.rds_credentials_secret_version_arn
  backend_env_secret_version_arn     = module.rds.backend_env_secret_version_arn
  tags                               = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix                = local.name_prefix
  aws_region                 = var.aws_region
  ecs_tasks_sg_id            = module.security_groups.ecs_tasks_sg_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_backend_subnet_ids = module.vpc.private_backend_subnet_ids
  execution_role_arn         = module.iam.ecs_task_execution_role_arn
  frontend_tg_arn            = module.alb.frontend_tg_arn
  backend_tg_arn             = module.alb.backend_tg_arn
  backend_env_secret_arn     = module.rds.backend_env_secret_arn
  log_retention_days         = var.log_retention_days
  frontend_desired_count     = var.frontend_desired_count
  backend_desired_count      = var.backend_desired_count
  frontend_cpu               = var.frontend_cpu
  frontend_memory            = var.frontend_memory
  backend_cpu                = var.backend_cpu
  backend_memory             = var.backend_memory
  tags                       = local.common_tags

  # Ensure ALB listeners and IAM roles are fully ready before ECS services
  depends_on = [module.alb, module.iam]
}

module "github_oidc" {
  source = "../../modules/github_oidc"

  name_prefix                 = local.name_prefix
  github_repo                 = var.github_repo
  github_main_branch          = var.github_main_branch
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  tags                        = local.common_tags
}

module "route53" {
  source = "../../modules/route53"

  name_prefix  = local.name_prefix
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  tags         = local.common_tags
}
