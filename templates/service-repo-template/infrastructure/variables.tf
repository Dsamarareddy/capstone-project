variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

# TODO(new-service): set this to your service's short name.
variable "app_name" {
  description = "Short application name used in resource naming."
  type        = string
  default     = "TODO-service-name"
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

# TODO(new-service): set this to the port your app listens on.
variable "container_port" {
  description = "Port the service listens on."
  type        = number
  default     = 3000
}
