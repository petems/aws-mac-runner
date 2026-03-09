require 'spec_helper'

describe 'profile::mac_runner::tools' do
  it { is_expected.to compile.with_all_deps }

  %w[jq gh cmake cocoapods fastlane].each do |pkg|
    it "installs #{pkg} via homebrew" do
      is_expected.to contain_package(pkg)
        .with_ensure('present')
        .with_provider('homebrew')
    end
  end

  it 'downloads swiftlint pkg' do
    is_expected.to contain_exec('download-swiftlint')
      .with_unless('/usr/bin/command -v swiftlint')
  end

  it 'installs swiftlint pkg' do
    is_expected.to contain_exec('install-swiftlint')
      .that_requires('Exec[download-swiftlint]')
  end

  it 'cleans up swiftlint pkg after install' do
    is_expected.to contain_exec('cleanup-swiftlint-pkg')
      .that_requires('Exec[install-swiftlint]')
  end

  context 'with custom swiftlint version' do
    let(:params) { { swiftlint_version: '0.60.0' } }

    it 'uses the specified version in the download URL' do
      is_expected.to contain_exec('download-swiftlint')
        .with_command(%r{/0\.60\.0/SwiftLint\.pkg})
    end
  end
end
