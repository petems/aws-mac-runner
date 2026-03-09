require 'spec_helper'

describe 'profile::mac_runner::runner_install' do
  it { is_expected.to compile.with_all_deps }

  it 'creates the runner directory' do
    is_expected.to contain_file('/Users/ec2-user/actions-runner')
      .with_ensure('directory')
      .with_owner('ec2-user')
  end

  it 'downloads the runner tarball via archive' do
    is_expected.to contain_archive('actions-runner.tar.gz')
      .with_source(%r{actions-runner-osx-arm64-.+\.tar\.gz$})
      .with_extract(true)
      .with_extract_path('/Users/ec2-user/actions-runner')
      .with_creates('/Users/ec2-user/actions-runner/config.sh')
      .with_cleanup(true)
      .that_requires('File[/Users/ec2-user/actions-runner]')
  end

  it 'configures the runner with idempotency guard' do
    is_expected.to contain_exec('configure-runner')
      .with_creates('/Users/ec2-user/actions-runner/.runner')
      .with_user('ec2-user')
      .with_cwd('/Users/ec2-user/actions-runner')
      .that_requires('Archive[actions-runner.tar.gz]')
  end

  it 'passes runner configuration flags' do
    is_expected.to contain_exec('configure-runner')
      .with_command(%r{--url https://github\.com/example/repo})
  end

  it 'uses --unattended --replace flags' do
    is_expected.to contain_exec('configure-runner')
      .with_command(%r{--unattended --replace})
  end

  context 'on x86_64 architecture' do
    let(:facts) do
      super().merge(
        'os' => super()['os'].merge('architecture' => 'x86_64'),
        'architecture' => 'x86_64',
      )
    end

    it 'downloads the x64 tarball' do
      is_expected.to contain_archive('actions-runner.tar.gz')
        .with_source(%r{actions-runner-osx-x64-.+\.tar\.gz$})
    end
  end
end
