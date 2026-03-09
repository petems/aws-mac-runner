require 'spec_helper'

describe 'profile::mac_runner::homebrew' do
  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_class('homebrew') }

  it 'adds brew shellenv to .zprofile' do
    is_expected.to contain_stdlib__file_line('brew-shellenv')
      .with_path('/Users/ec2-user/.zprofile')
      .with_line('eval "$(/opt/homebrew/bin/brew shellenv)"')
      .with_match('brew shellenv')
      .that_requires('Class[homebrew]')
  end
end
