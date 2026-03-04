#!/bin/bash
# Configure GitHub Actions runner as a launchd service
# Uses the runner's built-in svc.sh script
set -euo pipefail

LOG_PREFIX="[runner-service]"

log() {
  echo "$LOG_PREFIX $*"
}

RUNNER_DIR="$HOME/actions-runner"

if [[ ! -f "$RUNNER_DIR/svc.sh" ]]; then
  log "ERROR: Runner svc.sh not found at $RUNNER_DIR/svc.sh"
  log "Ensure install-github-runner.sh has run first"
  exit 1
fi

cd "$RUNNER_DIR"

# Install the service using the runner's built-in script
log "Installing runner service via svc.sh..."
sudo ./svc.sh install "$(whoami)"

# Start the service
log "Starting runner service..."
sudo ./svc.sh start

# Verify the service is running
log "Verifying service status..."
sudo ./svc.sh status

log "Runner service configured and started"
log "Service will auto-start on boot via launchd"
