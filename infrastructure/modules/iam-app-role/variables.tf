variable "name" {
  description = "Name prefix for the IAM roles (e.g. dev-ims)."
  type        = string
}

variable "allowed_actions" {
  description = "IAM actions the application's task role is permitted to perform (least privilege - caller must scope this to what the app actually needs)."
  type        = list(string)
  default     = []
}

variable "allowed_resources" {
  description = "ARNs (or patterns) the allowed_actions apply to. Defaults to none - a role with allowed_actions but no allowed_resources grants nothing."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to the IAM roles."
  type        = map(string)
  default     = {}
}
