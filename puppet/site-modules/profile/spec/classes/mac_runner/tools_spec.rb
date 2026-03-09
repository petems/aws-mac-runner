require 'spec_helper'

describe 'profile::mac_runner::tools' do
  it { is_expected.to compile.with_all_deps }

  %w[jq gh cmake cocoapods fastlane swiftlint].each do |pkg|
    it "installs #{pkg} via homebrew" do
      is_expected.to contain_package(pkg)
        .with_ensure('present')
        .with_provider('homebrew')
    end
  end
end
