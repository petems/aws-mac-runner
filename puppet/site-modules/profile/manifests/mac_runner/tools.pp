# @summary Install CI/CD tools via Homebrew and pre-built binaries
#
# Uses the thekevjames/homebrew package provider for Homebrew formulae
# and installs SwiftLint from a pre-built .pkg binary.
#
# @param brew_packages
#   List of Homebrew packages to install.
# @param swiftlint_version
#   Version of SwiftLint to install from GitHub releases.
class profile::mac_runner::tools (
  Array[String] $brew_packages    = ['jq', 'gh', 'cmake', 'cocoapods', 'fastlane'],
  String        $swiftlint_version = '0.63.2',
) {
  $brew_packages.each |String $pkg| {
    package { $pkg:
      ensure   => present,
      provider => 'homebrew',
    }
  }

  $swiftlint_pkg = '/tmp/SwiftLint.pkg'
  $swiftlint_url = "https://github.com/realm/SwiftLint/releases/download/${swiftlint_version}/SwiftLint.pkg"

  exec { 'download-swiftlint':
    command => "/usr/bin/curl -fsSL -o ${swiftlint_pkg} ${swiftlint_url}",
    creates => $swiftlint_pkg,
    unless  => '/usr/bin/command -v swiftlint',
    path    => ['/usr/bin', '/bin'],
  }

  exec { 'install-swiftlint':
    command     => "/usr/sbin/installer -pkg ${swiftlint_pkg} -target /",
    unless      => '/usr/bin/command -v swiftlint',
    require     => Exec['download-swiftlint'],
    provider    => 'shell',
  }

  exec { 'cleanup-swiftlint-pkg':
    command     => "/bin/rm -f ${swiftlint_pkg}",
    onlyif      => "/bin/test -f ${swiftlint_pkg}",
    require     => Exec['install-swiftlint'],
    refreshonly => false,
  }
}
