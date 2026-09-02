output "alb_dns_name" {
  description = "Public URL to reach the IMS API once deployed."
  value       = module.ims_service.alb_dns_name
}

output "ecr_repository_url" {
  description = "Push images here before deploying (docker push <this>:<tag>)."
  value       = module.ecr.repository_url
}

output "db_endpoint" {
  description = "RDS instance endpoint."
  value       = module.db.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the generated DB credentials."
  value       = module.db.secret_arn
}
