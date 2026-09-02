variable "name" {
  description = "Name prefix for the cluster, service, task definition, and load balancer (e.g. dev-ims)."
  type        = string
}

variable "image_url" {
  description = "Full image URL (e.g. <account>.dkr.ecr.<region>.amazonaws.com/dev-ims:tag) to run."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on (must match the app's HEALTHCHECK/listen port)."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "HTTP path the ALB target group uses for health checks."
  type        = string
  default     = "/health"
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running task copies."
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "VPC ID the ALB and service run in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Fargate tasks."
  type        = list(string)
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB on port 80 (restrict this to a VPN/office range in real deployments)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "execution_role_arn" {
  description = "ECS execution role ARN (from the iam-app-role module)."
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN (from the iam-app-role module)."
  type        = string
}

variable "environment" {
  description = "Plain environment variables for the container (non-secret values only)."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of container env var name to Secrets Manager ARN (colon-suffixed JSON key, e.g. arn:...:secret:foo::password::) injected as ECS task secrets."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the service's log group."
  type        = number
  default     = 400
}

variable "log_kms_key_id" {
  description = "KMS key ARN to encrypt the CloudWatch log group with. Leave null to use CloudWatch's default encryption (no customer-managed key assumed)."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. When set, the ALB terminates TLS on :443 and redirects :80 to it. Leave null for plain HTTP (this capstone's local/dev environment has no domain or ACM certificate to attach)."
  type        = string
  default     = null
}

variable "access_logs_bucket_id" {
  description = "S3 bucket ID to send ALB access logs to. Leave null to skip access logging (no target bucket assumed by default)."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection. Defaults to false so this dev environment can be cleanly `terraform destroy`ed; set true for any long-lived environment."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
