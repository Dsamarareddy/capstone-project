output "execution_role_arn" {
  description = "ARN of the ECS task execution role (used by ECS itself: image pull, log shipping, secret injection)."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role (used by the application code's own AWS SDK calls)."
  value       = aws_iam_role.task.arn
}
