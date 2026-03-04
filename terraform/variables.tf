variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "availability_zone" {
  description = "Availability zone for the dedicated host and subnet"
  type        = string
  default     = "us-east-2a"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "mac-runner"
}

variable "instance_type" {
  description = "Mac instance type (mac2.metal, mac2-m2.metal, mac2-m2pro.metal)"
  type        = string
  default     = "mac2.metal"

  validation {
    condition     = contains(["mac2.metal", "mac2-m2.metal", "mac2-m2pro.metal"], var.instance_type)
    error_message = "Instance type must be one of: mac2.metal (M1), mac2-m2.metal (M2), mac2-m2pro.metal (M2 Pro)."
  }
}

variable "macos_version" {
  description = "macOS version for AMI lookup (e.g., 14, 15)"
  type        = string
  default     = "15"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access. Leave empty for SSM-only access (recommended)."
  type        = list(string)
  default     = []
}

variable "github_runner_token" {
  description = "GitHub runner registration token"
  type        = string
  sensitive   = true
}

variable "github_runner_url" {
  description = "GitHub repository or organization URL for runner registration"
  type        = string
}

variable "github_runner_name" {
  description = "Name for the GitHub runner"
  type        = string
  default     = "mac-runner"
}

variable "github_runner_labels" {
  description = "Comma-separated labels for the GitHub runner"
  type        = string
  default     = "self-hosted,macOS,ARM64,apple-silicon"
}

variable "github_runner_group" {
  description = "Runner group to add the runner to (org-level runners only)"
  type        = string
  default     = "default"
}

variable "enable_ssm_logging" {
  description = "Enable CloudWatch logging for SSM sessions"
  type        = bool
  default     = false
}
