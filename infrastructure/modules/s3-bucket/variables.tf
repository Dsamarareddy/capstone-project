variable "bucket_name" {
  description = "Globally-unique S3 bucket name."
  type        = string
}

variable "versioning_enabled" {
  description = "Whether to enable object versioning."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it still contains objects (use only for ephemeral/dev buckets)."
  type        = bool
  default     = false
}

variable "access_log_bucket_id" {
  description = "Bucket ID to send S3 access logs to. Leave null to skip access logging (no target bucket assumed by default)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to the bucket."
  type        = map(string)
  default     = {}
}
