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

variable "tags" {
  description = "Common tags applied to the bucket."
  type        = map(string)
  default     = {}
}
