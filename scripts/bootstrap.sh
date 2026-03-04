#!/bin/bash
# Orchestrator script - runs all setup steps in order
# Executes as ec2-user
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="[bootstrap]"

log() {
  echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') $*"
}

log "Starting Mac runner bootstrap..."
log "Running as user: $(whoami)"
log "Architecture: $(uname -m)"
log "macOS version: $(sw_vers -productVersion)"

# Step 1: Homebrew
log "Step 1/5: Homebrew"
"$SCRIPT_DIR/install-homebrew.sh"

# Step 2: Xcode CLI Tools
log "Step 2/5: Xcode CLI Tools"
"$SCRIPT_DIR/install-xcode-cli-tools.sh"

# Step 3: Common tools
log "Step 3/5: Common tools"
"$SCRIPT_DIR/install-common-tools.sh"

# Step 4: GitHub Actions Runner
log "Step 4/5: GitHub Actions Runner"
"$SCRIPT_DIR/install-github-runner.sh"

# Step 5: Configure runner service
log "Step 5/5: Runner service"
"$SCRIPT_DIR/configure-runner-service.sh"

log "Bootstrap complete! Runner should be online in GitHub."
