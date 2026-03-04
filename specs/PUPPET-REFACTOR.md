# Puppet Refactor Plan for aws-mac-runner

## Current Bootstrap Surface (Reviewed)

- User data entrypoint: `scripts/user-data.sh.tftpl`
- Orchestration: `scripts/bootstrap.sh`
- Steps:
  1. `scripts/install-homebrew.sh`
  2. `scripts/install-xcode-cli-tools.sh`
  3. `scripts/install-common-tools.sh`
  4. `scripts/install-github-runner.sh`
  5. `scripts/configure-runner-service.sh`
- Cleanup path: `scripts/cleanup-host.sh`
- Terraform wiring: `terraform/main.tf`, `terraform/modules/mac-instance/main.tf`

## Puppet Target Design

1. Create module `profile::mac_runner` with ordered classes:
   - `profile::mac_runner::base` (dirs, env, common files)
   - `profile::mac_runner::homebrew`
   - `profile::mac_runner::xcode_cli_tools`
   - `profile::mac_runner::tools`
   - `profile::mac_runner::runner_install`
   - `profile::mac_runner::runner_service`
2. Use a role class `role::github_actions_mac_runner` that includes `profile::mac_runner`.
3. Keep Terraform `user_data`, but reduce it to:
   - install Puppet agent (or ensure `puppet apply` runtime)
   - write minimal Hiera/bootstrap config
   - run one initial Puppet apply

## Script-to-Puppet Mapping

1. `install-homebrew.sh` -> `package`/`exec` resources for Homebrew bootstrap; manage `/Users/ec2-user/.zprofile` with `file_line` or `file` template.
2. `install-xcode-cli-tools.sh` -> `exec` with `unless => 'xcode-select -p'`; optional follow-up `exec` for license accept.
3. `install-common-tools.sh` -> `package { ..., provider => homebrew }` for `jq/gh/cmake/cocoapods/fastlane`; SwiftLint via managed `.pkg` install (`exec` or `package` with apple provider path).
4. `install-github-runner.sh` -> resources for runner dir, tarball download/extract, then `exec` for `config.sh --unattended --replace` guarded by `unless` checks.
5. `configure-runner-service.sh` -> `exec` install/start, then `service` resource for launchd state (`ensure => running`, `enable => true`).
6. `cleanup-host.sh` -> move to Puppet Task/Bolt plan (operational action), not steady-state catalog.

## Data and Secrets Model

- Put non-secret runner settings in Hiera:
  - URL, name, labels, group, runner version, tool versions
- Store token as `Sensitive[String]` via Hiera `lookup_options` conversion.
- Important: GitHub registration token expires in 1 hour, so do not treat it as static desired-state data. Use one of:
  1. short-lived token injected only for first apply
  2. pre-step to fetch token and trigger apply immediately
  3. switch to GitHub App/PAT flow that can mint fresh registration tokens on demand

## Execution Ordering (Puppet Relationships)

- `Class['homebrew'] -> Class['xcode_cli_tools'] -> Class['tools'] -> Class['runner_install'] -> Class['runner_service']`
- Use `require/before/notify/subscribe` relationships.
- Use `exec` idempotency controls (`creates`, `unless`, `onlyif`, `refreshonly`).

## Recommended Migration Phases

1. Scaffold module/classes + Hiera schema; move only Homebrew and tool packages first.
2. Add Xcode CLI and SwiftLint package install idempotently.
3. Add runner download/configuration with pinned runner version (avoid "latest" drift).
4. Add launchd service management and health checks.
5. Replace current large embedded `user_data` with minimal Puppet bootstrap.
6. Add validation: `puppet parser validate`, `puppet-lint`, `rspec-puppet`, and one EC2 test run.

## Context7-Backed Decisions Used

- Launchd service management in Puppet `service` type.
- `exec` idempotency and refresh semantics.
- Sensitive data handling with Hiera `lookup_options` + `Sensitive`.
- Resource ordering with `require/before/subscribe/notify`.
