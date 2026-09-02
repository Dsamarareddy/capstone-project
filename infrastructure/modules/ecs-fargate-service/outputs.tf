output "alb_dns_name" {
  description = "Public DNS name of the ALB fronting the service."
  value       = aws_lb.this.dns_name
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_security_group_id" {
  description = "Security group ID attached to the running tasks (e.g. to allow it into the DB's security group)."
  value       = aws_security_group.service.id
}
