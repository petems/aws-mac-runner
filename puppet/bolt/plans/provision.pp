# @summary Provision a GitHub Actions runner on the target Mac instance
#
# Writes instance-specific Hiera data to the target, then applies the
# full runner role. This is the Bolt equivalent of the user-data bootstrap.
#
# @param targets
#   The targets to provision.
# @param github_runner_url
#   The GitHub repository or organization URL for runner registration.
# @param github_runner_token
#   Registration token (expires in 1 hour — generate immediately before running).
# @param github_runner_name
#   Display name for the runner in GitHub.
# @param github_runner_labels
#   Comma-separated labels for the runner.
# @param github_runner_group
#   Runner group name.
plan provision (
  TargetSpec $targets,
  String     $github_runner_url,
  Sensitive  $github_runner_token,
  String     $github_runner_name   = 'mac-runner',
  String     $github_runner_labels = 'self-hosted,macOS,ARM64,apple-silicon',
  String     $github_runner_group  = 'default',
) {
  $data_dir = '/etc/puppetlabs/puppet/data'

  # Ensure the Hiera data directory exists
  run_command("mkdir -p ${data_dir}", $targets)

  # Write instance-specific Hiera data
  $instance_yaml = @("YAML")
    ---
    profile::mac_runner::runner_install::github_runner_url: "${github_runner_url}"
    profile::mac_runner::runner_install::github_runner_token: "${github_runner_token.unwrap}"
    profile::mac_runner::runner_install::github_runner_name: "${github_runner_name}"
    profile::mac_runner::runner_install::github_runner_labels: "${github_runner_labels}"
    profile::mac_runner::runner_install::github_runner_group: "${github_runner_group}"
    | YAML

  run_command("cat > ${data_dir}/instance.yaml << 'INSTANCEEOF'\n${instance_yaml}INSTANCEEOF", $targets)

  out::message("Wrote instance.yaml to ${data_dir}/instance.yaml")

  # Apply the runner role
  apply($targets) {
    include role::github_actions_mac_runner
  }

  return 'Provisioning complete'
}
