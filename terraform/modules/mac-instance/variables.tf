variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "instance_type" {
  description = "Mac instance type (mac2.metal, mac2-m2.metal, mac2-m2pro.metal)"
  type        = string
}

variable "host_id" {
  description = "ID of the dedicated host"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to launch the instance in"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile"
  type        = string
}

variable "macos_version" {
  description = "macOS version to use for AMI lookup (e.g., 14, 15)"
  type        = string
  default     = "15"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 200
}

variable "root_volume_iops" {
  description = "IOPS for the root EBS gp3 volume"
  type        = number
  default     = 10000
}

variable "root_volume_throughput" {
  description = "Throughput in MiB/s for the root EBS gp3 volume"
  type        = number
  default     = 400
}

variable "user_data" {
  description = "User data script content"
  type        = string
  default     = null
}
