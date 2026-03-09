require 'spec_helper'

describe 'profile::mac_runner::runner_service' do
  it { is_expected.to compile.with_all_deps }

  it 'installs the runner service via svc.sh' do
    is_expected.to contain_exec('install-runner-service')
      .with_unless('/bin/ls /Library/LaunchDaemons/actions.runner.*.plist 2>/dev/null')
      .with_cwd('/Users/ec2-user/actions-runner')
  end

  it 'starts the runner service' do
    is_expected.to contain_exec('start-runner-service')
      .with_unless('/bin/launchctl list 2>/dev/null | /usr/bin/grep actions.runner')
      .that_requires('Exec[install-runner-service]')
  end
end
