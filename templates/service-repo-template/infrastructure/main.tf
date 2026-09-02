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
  }
}

# Do NOT change these module `source` lines when onboarding a new service - only the
# variables above and the module inputs below should differ per application.
# TODO(platform-owner): replace <org>/group1-advanced with this platform's real repo path
# once it exists on GitHub, and cut a `modules/v1.0.0` tag for consuming teams to pin to.

module "networking" {
  source   = "git::https://github.com/<org>/group1-advanced.git//infrastructure/modules/networking?ref=modules/v1.0.0"
  name     = local.name
  az_count = 2
  tags     = local.tags
}

module "ecr" {
  source = "git::https://github.com/<org>/group1-advanced.git//infrastructure/modules/ecr?ref=modules/v1.0.0"
  name   = local.name
  tags   = local.tags
}

module "db" {
  source     = "git::https://github.com/<org>/group1-advanced.git//infrastructure/modules/rds-postgres?ref=modules/v1.0.0"
  identifier = "${local.name}-db"
  db_name    = var.app_name
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  tags       = local.tags
}

module "iam" {
  source            = "git::https://github.com/<org>/group1-advanced.git//infrastructure/modules/iam-app-role?ref=modules/v1.0.0"
  name              = local.name
  allowed_actions   = ["secretsmanager:GetSecretValue"]
  allowed_resources = [module.db.secret_arn]
  tags              = local.tags
}

module "service" {
  source              = "git::https://github.com/<org>/group1-advanced.git//infrastructure/modules/ecs-fargate-service?ref=modules/v1.0.0"
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

resource "aws_security_group_rule" "db_from_service" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.db.db_security_group_id
  source_security_group_id = module.service.service_security_group_id
  description              = "Postgres from the ${local.name} ECS service"
}
