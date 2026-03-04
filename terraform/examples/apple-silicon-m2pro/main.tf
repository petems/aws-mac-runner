# Example: Apple Silicon M2 Pro runner
# This example deploys a mac2-m2pro.metal instance

module "mac_runner" {
  source = "../../"

  aws_region        = "us-east-2"
  availability_zone = "us-east-2a"
  environment       = "dev"
  name_prefix       = "m2pro-runner"

  # M2 Pro instance
  instance_type = "mac2-m2pro.metal"
  macos_version = "15"

  # Tuned EBS for heavy Xcode builds
  root_volume_size       = 300
  root_volume_iops       = 10000
  root_volume_throughput = 400

  # GitHub runner configuration
  github_runner_url    = var.github_runner_url
  github_runner_token  = var.github_runner_token
  github_runner_name   = "m2pro-runner"
  github_runner_labels = "self-hosted,macOS,ARM64,apple-silicon,m2pro"

  # SSM-only access (no SSH)
  ssh_allowed_cidrs = []

  # Enable SSM session logging
  enable_ssm_logging = true
}

output "instance_id" {
  value = module.mac_runner.instance_id
}

output "ssm_connect_command" {
  value = module.mac_runner.ssm_connect_command
}
