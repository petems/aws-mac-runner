# Agentless Puppet with Bolt

## Overview

The default provisioning flow embeds Puppet code in EC2 user-data: at first boot, `puppet-bootstrap.sh` installs the Puppet agent and runs `puppet apply` locally. This works well for initial provisioning but requires an **instance rebuild** to change configuration.

[Puppet Bolt](https://www.puppet.com/docs/bolt/latest/bolt.html) provides an agentless alternative. Bolt pushes Puppet catalogs from your workstation to the Mac instance over SSH, enabling:

- **Iterative development** — edit manifests locally and apply without rebuilding
- **Day-2 changes** — update tools, rotate tokens, or adjust config on a running instance
- **Testing** — validate Puppet code against a real Mac before baking it into user-data

The Bolt project lives in `puppet/bolt/` and reuses the same site-modules, Forge modules, and Hiera data as the user-data bootstrap path.

## Prerequisites

| Requirement | How to install |
|-------------|---------------|
| Puppet Bolt | `brew install --cask puppet-bolt` or see [Bolt install docs](https://www.puppet.com/docs/bolt/latest/bolt_installing.html) |
| Deployed Mac instance | `terraform apply` (see [Getting Started](03-getting-started.md)) |
| Forge modules installed | `cd puppet && r10k puppetfile install` |
| SSH or SSM access | See [Transport Options](#transport-options) below |

## Transport Options

### SSH (simple)

Requires the `ssh_allowed_cidrs` Terraform variable to include your IP address, and the instance's SSH key pair.

```bash
# Ensure your IP is allowed through the security group
terraform apply -var='ssh_allowed_cidrs=["203.0.113.10/32"]'
```

### SSM Port-Forwarding Tunnel (secure, no open ports)

If you prefer not to open SSH ports, use AWS Systems Manager to create a tunnel:

```bash
# Start an SSM port-forwarding session (runs in background)
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile ese-sandbox &

# Then point Bolt at localhost:2222 in your inventory
```

The SSM approach requires no inbound security-group rules — only the instance's IAM role and your AWS credentials.

## Setting Up the Bolt Project

### Directory layout

```
puppet/bolt/
├── Boltdir/
│   ├── bolt-project.yaml       # Project config (modulepath, hiera)
│   ├── inventory.yaml.example  # Template — copy to inventory.yaml
│   └── inventory.yaml          # Your local inventory (git-ignored)
└── plans/
    ├── cleanup.pp              # De-register and remove the runner
    └── provision.pp            # Apply the full runner role
```

### Configure inventory

```bash
cd puppet/bolt/Boltdir
cp inventory.yaml.example inventory.yaml
# Edit inventory.yaml — set the IP/hostname of your Mac instance
```

### Install Forge modules

The Bolt project shares modules with the user-data path. Install them once from the repo root:

```bash
cd puppet && r10k puppetfile install
```

This populates `puppet/modules/` with the Forge dependencies listed in `puppet/Puppetfile`.

## Running `bolt apply`

The quickest way to apply the full runner configuration:

```bash
cd puppet/bolt

bolt apply \
  --targets mac_runners \
  -e 'include role::github_actions_mac_runner'
```

The `bolt-project.yaml` already configures `modulepath` and `hiera-config` to point at the shared Puppet directories, so no extra flags are needed.

> **Note:** `bolt apply` requires `puppet-agent` on the target. If the instance was provisioned via user-data, it's already installed. For a fresh instance, Bolt can install it automatically with `bolt puppetfile install` or you can use `bolt task run puppet_agent::install --targets mac_runners`.

## Instance-Specific Data

The runner needs per-instance values: the GitHub URL, registration token, runner name, and labels. These are normally written to `puppet/data/instance.yaml` during the user-data bootstrap. With Bolt, you have two options:

### Option 1: Use the provision plan (recommended)

The `provision` plan accepts parameters and writes `instance.yaml` on the target before applying:

```bash
cd puppet/bolt

bolt plan run provision \
  --targets mac_runners \
  github_runner_url='https://github.com/your-org/your-repo' \
  github_runner_token='AABCDEF...' \
  github_runner_name='mac-runner-01' \
  github_runner_labels='self-hosted,macOS,ARM64'
```

### Option 2: Write instance.yaml manually

Create `puppet/data/instance.yaml` locally, then copy it to the target:

```yaml
# puppet/data/instance.yaml
profile::mac_runner::runner_install::github_runner_url: "https://github.com/your-org/your-repo"
profile::mac_runner::runner_install::github_runner_token: "AABCDEF..."
profile::mac_runner::runner_install::github_runner_name: "mac-runner-01"
profile::mac_runner::runner_install::github_runner_labels: "self-hosted,macOS,ARM64"
```

```bash
bolt file upload puppet/data/instance.yaml /etc/puppetlabs/puppet/data/instance.yaml \
  --targets mac_runners --run-as root

bolt apply --targets mac_runners -e 'include role::github_actions_mac_runner'
```

> **Important:** Runner registration tokens expire in **1 hour**. Generate the token immediately before running Bolt.

## Using the Provision Plan

The `provision` plan (`puppet/bolt/plans/provision.pp`) combines token delivery and catalog application in a single command:

```bash
# Generate token and provision in one shot
RUNNER_TOKEN=$(gh api -X POST repos/{owner}/{repo}/actions/runners/registration-token --jq '.token')

bolt plan run provision \
  --targets mac_runners \
  github_runner_url='https://github.com/your-org/your-repo' \
  github_runner_token="$RUNNER_TOKEN" \
  github_runner_name='mac-runner-01'
```

**Parameters:**

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `targets` | yes | — | Bolt target spec |
| `github_runner_url` | yes | — | Repository or org URL |
| `github_runner_token` | yes | — | Registration token (1h TTL) |
| `github_runner_name` | no | `mac-runner` | Runner display name |
| `github_runner_labels` | no | `self-hosted,macOS,ARM64,apple-silicon` | Comma-separated labels |
| `github_runner_group` | no | `default` | Runner group |

## Day-2 Operations

### Re-apply configuration changes

Edit manifests or Hiera data locally, then push:

```bash
bolt apply --targets mac_runners -e 'include role::github_actions_mac_runner'
```

### Update a single tool

```bash
bolt command run 'brew upgrade jq' --targets mac_runners
```

### Run cleanup before teardown

```bash
RUNNER_TOKEN=$(gh api -X POST repos/{owner}/{repo}/actions/runners/remove-token --jq '.token')

bolt plan run cleanup \
  --targets mac_runners \
  github_runner_token="$RUNNER_TOKEN"
```

## Comparison: User-Data Bootstrap vs Bolt Apply

| Aspect | User-Data Bootstrap | Bolt Apply |
|--------|-------------------|------------|
| **When it runs** | Once at first boot | On-demand from workstation |
| **Connectivity** | None (runs locally) | SSH or SSM tunnel |
| **Iteration speed** | Slow (rebuild instance) | Fast (seconds) |
| **Day-2 changes** | Rebuild required | Re-apply anytime |
| **Token delivery** | Terraform variable | Plan parameter or manual |
| **Puppet agent** | Installed by bootstrap | Must be pre-installed or auto-installed |
| **Best for** | Production provisioning | Development, testing, day-2 ops |

## Troubleshooting

### Connection refused / timeout

- **SSH transport:** Verify `ssh_allowed_cidrs` includes your IP. Check security group rules in the AWS console.
- **SSM tunnel:** Ensure the tunnel process is running (`aws ssm start-session ...`). Verify your AWS credentials and the instance's IAM role.

### puppet-agent not found on target

Bolt requires `puppet-agent` on the target to compile catalogs. Install it:

```bash
bolt task run puppet_agent::install --targets mac_runners
```

Or, if the instance was previously provisioned via user-data, the agent is already present at `/opt/puppetlabs/bin/puppet`.

### Module not found errors

Ensure Forge modules are installed:

```bash
cd puppet && r10k puppetfile install
```

This must be done before the first `bolt apply`. The modules in `puppet/modules/` are git-ignored and not checked in.

### Permission denied during apply

Bolt needs root privileges to manage system resources. Add `--run-as root` or configure `run-as` in your inventory:

```yaml
config:
  ssh:
    run-as: root
```

### Hiera data not found

Verify that `bolt-project.yaml` points to the correct `hiera-config` path and that `puppet/data/common.yaml` exists. For instance-specific data, ensure `instance.yaml` is present in `puppet/data/` on the target (the `provision` plan handles this automatically).
