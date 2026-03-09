# @summary Install Xcode Command Line Tools
#
# Custom implementation because no maintained community module exists.
# Uses softwareupdate to install and guards with xcode-select -p.
class profile::mac_runner::xcode_cli_tools {
  exec { 'install-xcode-cli-tools':
    command  => '/bin/bash -c "touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress && PROD=$(/usr/sbin/softwareupdate -l 2>/dev/null | /usr/bin/grep -B 1 \"Command Line Tools\" | /usr/bin/grep -o \"Command Line Tools.*\" | /usr/bin/head -1) && /usr/sbin/softwareupdate -i \"$PROD\" --verbose && /bin/rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"',
    unless   => '/usr/bin/xcode-select -p',
    timeout  => 1800,
    provider => 'shell',
  }

  exec { 'accept-xcode-license':
    command     => '/usr/bin/sudo /usr/bin/xcodebuild -license accept',
    unless      => '/usr/bin/xcodebuild -checkFirstLaunchStatus 2>/dev/null',
    require     => Exec['install-xcode-cli-tools'],
    returns     => [0, 69],
    provider    => 'shell',
  }
}
