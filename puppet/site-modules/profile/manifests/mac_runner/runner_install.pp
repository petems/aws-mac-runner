# @summary Download and configure GitHub Actions self-hosted runner
#
# Uses puppet/archive for tarball download and extraction.
# Runner version is pinned via Hiera instead of fetching latest.
#
# @param runner_version
#   Pinned version of the GitHub Actions runner.
# @param runner_dir
#   Directory to install the runner into.
# @param github_runner_url
#   GitHub repository or organization URL.
# @param github_runner_token
#   Registration token (Sensitive).
# @param github_runner_name
#   Name for the runner instance.
# @param github_runner_labels
#   Comma-separated labels.
# @param github_runner_group
#   Runner group name.
class profile::mac_runner::runner_install (
  String              $runner_version      = '2.322.0',
  String              $runner_dir          = '/Users/ec2-user/actions-runner',
  String              $github_runner_url   = '',
  Sensitive[String]   $github_runner_token = Sensitive(''),
  String              $github_runner_name  = 'mac-runner',
  String              $github_runner_labels = 'self-hosted,macOS,ARM64,apple-silicon',
  String              $github_runner_group = 'default',
) {
  $runner_user = 'ec2-user'

  # Determine architecture suffix for tarball
  $arch_suffix = $facts['os']['architecture'] ? {
    'arm64'  => 'arm64',
    'x86_64' => 'x64',
    default  => fail("Unsupported architecture: ${facts['os']['architecture']}"),
  }

  $tarball_name = "actions-runner-osx-${arch_suffix}-${runner_version}.tar.gz"
  $tarball_url  = "https://github.com/actions/runner/releases/download/v${runner_version}/${tarball_name}"

  file { $runner_dir:
    ensure => directory,
    owner  => $runner_user,
    group  => 'staff',
    mode   => '0755',
  }

  archive { 'actions-runner.tar.gz':
    path         => "/tmp/${tarball_name}",
    source       => $tarball_url,
    extract      => true,
    extract_path => $runner_dir,
    creates      => "${runner_dir}/config.sh",
    cleanup      => true,
    user         => $runner_user,
    group        => 'staff',
    require      => File[$runner_dir],
  }

  # Unwrap the Sensitive token for use in the command
  $token_value = $github_runner_token.unwrap

  exec { 'configure-runner':
    command     => "${runner_dir}/config.sh --url ${github_runner_url} --token ${token_value} --name ${github_runner_name} --labels ${github_runner_labels} --runnergroup ${github_runner_group} --work _work --unattended --replace",
    creates     => "${runner_dir}/.runner",
    user        => $runner_user,
    cwd         => $runner_dir,
    environment => ["HOME=/Users/${runner_user}"],
    timeout     => 300,
    require     => Archive['actions-runner.tar.gz'],
    provider    => 'shell',
  }
}
