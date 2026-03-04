variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "iam_role_name" {
  description = "Name of the IAM role to attach SSM policies to"
  type        = string
}

variable "enable_session_logging" {
  description = "Enable CloudWatch logging for SSM sessions"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain SSM session logs"
  type        = number
  default     = 30
}
