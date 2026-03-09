# @summary Role for GitHub Actions self-hosted runner on macOS
class role::github_actions_mac_runner {
  include profile::mac_runner
}
