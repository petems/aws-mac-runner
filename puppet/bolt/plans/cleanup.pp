# @summary Stop, uninstall, and de-register the GitHub Actions runner
#
# This is an operational plan (not part of the Puppet catalog).
# Run before terraform destroy.
#
# @param targets
#   The targets to clean up.
# @param runner_dir
#   Directory where the runner is installed.
# @param github_runner_token
#   Token for de-registering the runner from GitHub.
plan cleanup (
  TargetSpec        $targets,
  String            $runner_dir          = '/Users/ec2-user/actions-runner',
  Optional[String]  $github_runner_token = undef,
) {
  # Stop the runner service
  run_command("sudo ${runner_dir}/svc.sh stop || true", $targets,
    '_catch_errors' => true,
  )

  # Uninstall the runner service
  run_command("sudo ${runner_dir}/svc.sh uninstall || true", $targets,
    '_catch_errors' => true,
  )

  # De-register the runner if a token is provided
  if $github_runner_token {
    run_command("cd ${runner_dir} && ./config.sh remove --token ${github_runner_token}", $targets,
      '_catch_errors' => true,
    )
  } else {
    out::message('No token provided - de-register the runner manually in GitHub Settings > Actions > Runners')
  }

  return 'Cleanup complete'
}
