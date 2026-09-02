variable "identifier" {
  description = "RDS instance identifier (e.g. dev-ims-db)."
  type        = string
}

variable "db_name" {
  description = "Name of the default database created on the instance."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the instance's security group is created in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs the DB subnet group spans (must not be public subnets)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs permitted to connect to Postgres on port 5432 (e.g. an ECS service's security group). No ingress is opened if this is empty."
  type        = list(string)
  default     = []
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "multi_az" {
  description = "Whether to deploy a standby replica in a second AZ."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable RDS deletion protection. Defaults to false so this dev environment can be cleanly `terraform destroy`ed; set true for any long-lived environment."
  type        = bool
  default     = false
}

variable "master_username" {
  description = "Master username for the instance."
  type        = string
  default     = "ims_admin"
}

variable "tags" {
  description = "Common tags applied to the instance and its secret."
  type        = map(string)
  default     = {}
}
