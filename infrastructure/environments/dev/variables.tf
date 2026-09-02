variable "aws_region" {
  description = "AWS region to deploy the dev environment into."
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Short application name used in resource naming (e.g. ims)."
  type        = string
  default     = "ims"
}

variable "environment_name" {
  description = "Environment name used in resource naming and tags."
  type        = string
  default     = "dev"
}

variable "container_image_tag" {
  description = "Tag of the image (pushed to the ecr module's repository) to deploy."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the IMS API listens on."
  type        = number
  default     = 3000
}
