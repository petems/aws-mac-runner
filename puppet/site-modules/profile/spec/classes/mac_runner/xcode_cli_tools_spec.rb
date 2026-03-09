require 'spec_helper'

describe 'profile::mac_runner::xcode_cli_tools' do
  it { is_expected.to compile.with_all_deps }

  it 'installs xcode cli tools with idempotency guard' do
    is_expected.to contain_exec('install-xcode-cli-tools')
      .with_unless('/usr/bin/xcode-select -p')
      .with_timeout(1800)
  end

  it 'accepts the xcode license' do
    is_expected.to contain_exec('accept-xcode-license')
      .that_requires('Exec[install-xcode-cli-tools]')
  end
end
