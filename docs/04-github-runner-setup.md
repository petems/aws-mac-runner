# GitHub Runner Setup

## Runner Registration Tokens

### Token Types

| Scope | API Endpoint | Permission Required |
|-------|-------------|---------------------|
| Repository | `POST /repos/{owner}/{repo}/actions/runners/registration-token` | Admin |
| Organization | `POST /orgs/{org}/actions/runners/registration-token` | Org owner |

### Generating Tokens

```bash
# Repository-level runner
gh api -X POST repos/{owner}/{repo}/actions/runners/registration-token --jq '.token'

# Organization-level runner
gh api -X POST orgs/{org}/actions/runners/registration-token --jq '.token'
```

Tokens expire after **1 hour**. Generate a fresh token immediately before running `terraform apply`.

### Token Security

- Never commit tokens to version control
- Pass tokens via `terraform apply -var="github_runner_token=..."` or environment variables
- The token is used once during registration and is not stored by the runner

## Runner Labels

Default labels configured by this project:

```
self-hosted, macOS, ARM64, apple-silicon
```

Use these labels in your workflow `runs-on`:

```yaml
jobs:
  build:
    runs-on: [self-hosted, macOS, ARM64]
```

Customize labels via the `github_runner_labels` variable:

```hcl
github_runner_labels = "self-hosted,macOS,ARM64,apple-silicon,xcode-15"
```

## Runner Service (launchd)

The runner is installed as a launchd service using the runner's built-in `svc.sh` script. This ensures:

- Runner starts automatically on boot
- Runner restarts if it crashes
- Runner runs as `ec2-user` (not root)

### Service Management

```bash
# SSH or SSM into the instance, then:
cd ~/actions-runner

# Check status
sudo ./svc.sh status

# Stop the runner
sudo ./svc.sh stop

# Start the runner
sudo ./svc.sh start

# Uninstall the service
sudo ./svc.sh uninstall
```

### Service Logs

```bash
# Runner logs
ls ~/actions-runner/_diag/

# launchd logs
log show --predicate 'subsystem == "com.github.actions.runner"' --last 1h
```

## Ephemeral vs Persistent Runners

This project configures a **persistent** runner by default. The runner stays registered and picks up jobs continuously.

### Ephemeral Mode

For better security isolation (each job gets a clean environment), add the `--ephemeral` flag to `install-github-runner.sh`:

```bash
./config.sh \
  --url "$GITHUB_RUNNER_URL" \
  --token "$GITHUB_RUNNER_TOKEN" \
  --ephemeral \
  --unattended
```

With ephemeral runners:
- The runner de-registers after completing one job
- You need automation to re-register or recreate the instance
- Better suited for production with AMI baking + auto-scaling

## Runner Groups (Organization Only)

For organization runners, you can assign runners to groups to control which repositories can use them:

```hcl
github_runner_group = "macos-builders"
```

Configure group permissions in **Organization Settings > Actions > Runner groups**.

## Troubleshooting Runner Registration

See [07-troubleshooting.md](07-troubleshooting.md) for common issues.
