#!/bin/bash
# Clean up Mac instance before de-registering/destroying
# Run this before terraform destroy
set -euo pipefail

LOG_PREFIX="[cleanup]"

log() {
  echo "$LOG_PREFIX $*"
}

RUNNER_DIR="$HOME/actions-runner"

# Stop and uninstall the runner service
if [[ -f "$RUNNER_DIR/svc.sh" ]]; then
  log "Stopping runner service..."
  sudo "$RUNNER_DIR/svc.sh" stop || true
  log "Uninstalling runner service..."
  sudo "$RUNNER_DIR/svc.sh" uninstall || true
fi

# De-register the runner from GitHub
if [[ -f "$RUNNER_DIR/config.sh" ]]; then
  log "Removing runner registration..."
  if [[ -n "${GITHUB_RUNNER_TOKEN:-}" ]]; then
    cd "$RUNNER_DIR"
    ./config.sh remove --token "$GITHUB_RUNNER_TOKEN" || log "WARNING: Failed to de-register runner"
  else
    log "WARNING: GITHUB_RUNNER_TOKEN not set, cannot de-register runner"
    log "De-register manually: Settings > Actions > Runners in GitHub"
  fi
fi

log "Cleanup complete"
log "You can now safely run 'terraform destroy'"
