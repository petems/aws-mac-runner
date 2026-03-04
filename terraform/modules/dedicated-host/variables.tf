variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "instance_type" {
  description = "Mac instance type (mac2.metal, mac2-m2.metal, mac2-m2pro.metal)"
  type        = string

  validation {
    condition     = contains(["mac2.metal", "mac2-m2.metal", "mac2-m2pro.metal"], var.instance_type)
    error_message = "Instance type must be one of: mac2.metal (M1), mac2-m2.metal (M2), mac2-m2pro.metal (M2 Pro)."
  }
}

variable "availability_zone" {
  description = "Availability zone for the dedicated host"
  type        = string
}
