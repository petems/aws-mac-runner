# @summary Configure and start the GitHub Actions runner as a launchd service
#
# Uses the runner's built-in svc.sh script to install and manage the service.
# Dynamic plist name means we guard on the existence of any actions.runner.* plist.
#
# @param runner_dir
#   Directory where the runner is installed.
# @param runner_user
#   The user that runs the GitHub Actions runner.
class profile::mac_runner::runner_service (
  String $runner_dir  = '/Users/ec2-user/actions-runner',
  String $runner_user = 'ec2-user',
) {
  exec { 'install-runner-service':
    command  => "sudo ${runner_dir}/svc.sh install ${runner_user}",
    unless   => '/bin/ls /Library/LaunchDaemons/actions.runner.*.plist 2>/dev/null',
    cwd      => $runner_dir,
    path     => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
    provider => 'shell',
  }

  exec { 'start-runner-service':
    command  => "sudo ${runner_dir}/svc.sh start",
    unless   => '/bin/launchctl list 2>/dev/null | /usr/bin/grep actions.runner',
    cwd      => $runner_dir,
    path     => ['/usr/bin', '/bin', '/usr/sbin', '/sbin'],
    require  => Exec['install-runner-service'],
    provider => 'shell',
  }
}
