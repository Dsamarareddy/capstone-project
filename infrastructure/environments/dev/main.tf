terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "${var.environment_name}-${var.app_name}"
  tags = {
    Environment = var.environment_name
    Application = var.app_name
    ManagedBy   = "terraform"
    Repository  = "group1-advanced"
  }
}

module "networking" {
  source   = "../../modules/networking"
  name     = local.name
  az_count = 2
  tags     = local.tags
}

module "ecr" {
  source = "../../modules/ecr"
  name   = local.name
  tags   = local.tags
}

module "db" {
  source     = "../../modules/rds-postgres"
  identifier = "${local.name}-db"
  db_name    = var.app_name
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  tags       = local.tags
}

module "iam" {
  source            = "../../modules/iam-app-role"
  name              = local.name
  allowed_actions   = ["secretsmanager:GetSecretValue"]
  allowed_resources = [module.db.secret_arn]
  tags              = local.tags
}

module "ims_service" {
  source              = "../../modules/ecs-fargate-service"
  name                = local.name
  image_url           = "${module.ecr.repository_url}:${var.container_image_tag}"
  container_port      = var.container_port
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  execution_role_arn  = module.iam.execution_role_arn
  task_role_arn       = module.iam.task_role_arn
  environment = {
    PORT = tostring(var.container_port)
  }
  secrets = {
    DATABASE_SECRET_ARN = module.db.secret_arn
  }
  tags = local.tags
}

# Breaks the db <-> ecs mutual dependency: the DB module never references the ECS
# service module directly (see infrastructure/modules/rds-postgres/README.md), so this
# root-level rule is what actually opens port 5432 from the running tasks to the database.
resource "aws_security_group_rule" "db_from_ims_service" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.db.db_security_group_id
  source_security_group_id = module.ims_service.service_security_group_id
  description              = "Postgres from the ${local.name} ECS service"
}
