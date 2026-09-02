output "endpoint" {
  description = "Connection endpoint (host) of the RDS instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port the instance listens on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the default database."
  value       = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the generated master credentials."
  value       = aws_secretsmanager_secret.this.arn
}

output "db_security_group_id" {
  description = "ID of the instance's own security group, so callers can attach ingress rules after both sides of a dependency cycle exist (see environments/dev/main.tf)."
  value       = aws_security_group.db.id
}
