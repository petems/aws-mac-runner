require 'spec_helper'

describe 'profile::mac_runner' do
  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_class('profile::mac_runner::base') }
  it { is_expected.to contain_class('profile::mac_runner::homebrew') }
  it { is_expected.to contain_class('profile::mac_runner::xcode_cli_tools') }
  it { is_expected.to contain_class('profile::mac_runner::tools') }
  it { is_expected.to contain_class('profile::mac_runner::runner_install') }
  it { is_expected.to contain_class('profile::mac_runner::runner_service') }

  it 'enforces ordering: base before homebrew' do
    is_expected.to contain_class('profile::mac_runner::base')
      .that_comes_before('Class[profile::mac_runner::homebrew]')
  end

  it 'enforces ordering: homebrew before xcode_cli_tools' do
    is_expected.to contain_class('profile::mac_runner::homebrew')
      .that_comes_before('Class[profile::mac_runner::xcode_cli_tools]')
  end

  it 'enforces ordering: xcode_cli_tools before tools' do
    is_expected.to contain_class('profile::mac_runner::xcode_cli_tools')
      .that_comes_before('Class[profile::mac_runner::tools]')
  end

  it 'enforces ordering: tools before runner_install' do
    is_expected.to contain_class('profile::mac_runner::tools')
      .that_comes_before('Class[profile::mac_runner::runner_install]')
  end

  it 'enforces ordering: runner_install before runner_service' do
    is_expected.to contain_class('profile::mac_runner::runner_install')
      .that_comes_before('Class[profile::mac_runner::runner_service]')
  end
end
