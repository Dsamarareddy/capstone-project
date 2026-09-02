variable "name" {
  description = "Name of the ECR repository (e.g. dev-ims)."
  type        = string
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten (IMMUTABLE recommended for production)."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "max_image_count" {
  description = "Maximum number of images to retain before the lifecycle policy expires the oldest."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Common tags applied to the repository."
  type        = map(string)
  default     = {}
}
