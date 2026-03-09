# @summary Install CI/CD tools via Homebrew
#
# Uses the thekevjames/homebrew package provider for Homebrew formulae.
#
# @param brew_packages
#   List of Homebrew packages to install.
class profile::mac_runner::tools (
  Array[String] $brew_packages = ['jq', 'gh', 'cmake', 'cocoapods', 'fastlane', 'swiftlint'],
) {
  $brew_packages.each |String $pkg| {
    package { $pkg:
      ensure   => present,
      provider => 'homebrew',
    }
  }
}
