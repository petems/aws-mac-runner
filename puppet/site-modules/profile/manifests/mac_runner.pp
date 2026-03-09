# @summary Wrapper profile for macOS GitHub Actions runner
#
# Includes all sub-profiles in dependency order.
class profile::mac_runner {
  include profile::mac_runner::base
  include profile::mac_runner::homebrew
  include profile::mac_runner::xcode_cli_tools
  include profile::mac_runner::tools
  include profile::mac_runner::runner_install
  include profile::mac_runner::runner_service

  Class['profile::mac_runner::base']
  -> Class['profile::mac_runner::homebrew']
  -> Class['profile::mac_runner::xcode_cli_tools']
  -> Class['profile::mac_runner::tools']
  -> Class['profile::mac_runner::runner_install']
  -> Class['profile::mac_runner::runner_service']
}
