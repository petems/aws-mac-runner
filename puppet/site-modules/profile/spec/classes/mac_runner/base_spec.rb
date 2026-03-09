require 'spec_helper'

describe 'profile::mac_runner::base' do
  it { is_expected.to compile.with_all_deps }

  it 'creates the log directory' do
    is_expected.to contain_file('/var/log/mac-runner')
      .with_ensure('directory')
      .with_owner('root')
      .with_group('wheel')
      .with_mode('0755')
  end

  it 'ensures the runner home directory exists' do
    is_expected.to contain_file('/Users/ec2-user')
      .with_ensure('directory')
      .with_owner('ec2-user')
      .with_group('staff')
  end

  it 'creates the managed marker file' do
    is_expected.to contain_file('/Users/ec2-user/.mac-runner-managed')
      .with_ensure('file')
      .with_owner('ec2-user')
  end
end
