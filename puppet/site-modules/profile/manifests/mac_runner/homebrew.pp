# @summary Install and configure Homebrew
#
# Uses the thekevjames/homebrew community module for installation
# and ensures brew shellenv is in the user's .zprofile.
#
# @param brew_path
#   Path to the Homebrew binary (Apple Silicon default).
class profile::mac_runner::homebrew (
  String $brew_path = '/opt/homebrew/bin/brew',
) {
  include homebrew

  $shell_profile = '/Users/ec2-user/.zprofile'

  stdlib::file_line { 'brew-shellenv':
    ensure  => present,
    path    => $shell_profile,
    line    => 'eval "$(/opt/homebrew/bin/brew shellenv)"',
    match   => 'brew shellenv',
    require => Class['homebrew'],
  }
}
