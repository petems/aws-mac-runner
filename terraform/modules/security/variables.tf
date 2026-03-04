variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed SSH access. Leave empty to disable SSH ingress (recommended - use SSM instead)."
  type        = list(string)
  default     = []
}
