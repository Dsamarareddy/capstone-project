output "alb_dns_name" {
  description = "Public URL to reach the service once deployed."
  value       = module.service.alb_dns_name
}

output "ecr_repository_url" {
  description = "Push images here before deploying."
  value       = module.ecr.repository_url
}
