module "networking" {
  source = "./modules/networking"

  name_prefix        = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "dedicated_host" {
  source = "./modules/dedicated-host"

  name_prefix       = var.name_prefix
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
}

module "security" {
  source = "./modules/security"

  name_prefix       = var.name_prefix
  vpc_id            = module.networking.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

module "mac_instance" {
  source = "./modules/mac-instance"

  name_prefix            = var.name_prefix
  instance_type          = var.instance_type
  host_id                = module.dedicated_host.host_id
  subnet_id              = module.networking.public_subnet_id
  security_group_id      = module.security.security_group_id
  instance_profile_name  = module.security.instance_profile_name
  macos_version          = var.macos_version
  root_volume_size       = var.root_volume_size
  root_volume_iops       = var.root_volume_iops
  root_volume_throughput = var.root_volume_throughput

  user_data = templatefile("${path.module}/../scripts/user-data.sh.tftpl", {
    github_runner_token             = var.github_runner_token
    github_runner_url               = var.github_runner_url
    github_runner_name              = var.github_runner_name
    github_runner_labels            = var.github_runner_labels
    github_runner_group             = var.github_runner_group
    script_bootstrap                = file("${path.module}/../scripts/bootstrap.sh")
    script_install_homebrew         = file("${path.module}/../scripts/install-homebrew.sh")
    script_install_xcode_cli_tools  = file("${path.module}/../scripts/install-xcode-cli-tools.sh")
    script_install_common_tools     = file("${path.module}/../scripts/install-common-tools.sh")
    script_install_github_runner    = file("${path.module}/../scripts/install-github-runner.sh")
    script_configure_runner_service = file("${path.module}/../scripts/configure-runner-service.sh")
  })
}

module "ssm" {
  source = "./modules/ssm"

  name_prefix            = var.name_prefix
  iam_role_name          = module.security.iam_role_name
  enable_session_logging = var.enable_ssm_logging
}
