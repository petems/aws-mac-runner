# @summary Base setup: directories and marker file
#
# @param log_dir
#   Directory for bootstrap logs.
# @param runner_user
#   The user that runs the GitHub Actions runner.
# @param runner_home
#   Home directory of the runner user.
class profile::mac_runner::base (
  String $log_dir     = '/var/log/mac-runner',
  String $runner_user = 'ec2-user',
  String $runner_home = '/Users/ec2-user',
) {
  file { $log_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'wheel',
    mode   => '0755',
  }

  file { $runner_home:
    ensure => directory,
    owner  => $runner_user,
    group  => 'staff',
    mode   => '0755',
  }

  file { "${runner_home}/.mac-runner-managed":
    ensure  => file,
    owner   => $runner_user,
    group   => 'staff',
    mode    => '0644',
    content => "Managed by Puppet - $(date)\n",
  }
}
