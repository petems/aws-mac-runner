#!/bin/bash
# Download and configure GitHub Actions self-hosted runner
# Requires: GITHUB_RUNNER_TOKEN, GITHUB_RUNNER_URL
set -euo pipefail

LOG_PREFIX="[github-runner]"

log() {
  echo "$LOG_PREFIX $*"
}

# Validate required environment variables
: "${GITHUB_RUNNER_TOKEN:?GITHUB_RUNNER_TOKEN is required}"
: "${GITHUB_RUNNER_URL:?GITHUB_RUNNER_URL is required}"
GITHUB_RUNNER_NAME="${GITHUB_RUNNER_NAME:-$(hostname)}"
GITHUB_RUNNER_LABELS="${GITHUB_RUNNER_LABELS:-self-hosted,macOS,ARM64,apple-silicon}"
GITHUB_RUNNER_GROUP="${GITHUB_RUNNER_GROUP:-default}"

RUNNER_DIR="$HOME/actions-runner"
ARCH="$(uname -m)"

log "Configuring runner for: $GITHUB_RUNNER_URL"
log "Runner name: $GITHUB_RUNNER_NAME"
log "Labels: $GITHUB_RUNNER_LABELS"
log "Architecture: $ARCH"

# Determine architecture suffix
case "$ARCH" in
  arm64)
    RUNNER_ARCH="arm64"
    ;;
  x86_64)
    RUNNER_ARCH="x64"
    ;;
  *)
    log "ERROR: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Get latest runner version
log "Fetching latest runner release..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

if [[ -z "$LATEST_VERSION" ]]; then
  log "ERROR: Could not determine latest runner version"
  exit 1
fi

log "Latest runner version: $LATEST_VERSION"

# Download runner
RUNNER_TARBALL="actions-runner-osx-${RUNNER_ARCH}-${LATEST_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/${RUNNER_TARBALL}"

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [[ -f "./config.sh" ]]; then
  log "Runner already downloaded, skipping download"
else
  log "Downloading runner from: $RUNNER_URL"
  curl -sL "$RUNNER_URL" -o "$RUNNER_TARBALL"
  tar xzf "$RUNNER_TARBALL"
  rm -f "$RUNNER_TARBALL"
  log "Runner extracted to $RUNNER_DIR"
fi

# Configure runner (unattended)
log "Configuring runner..."
./config.sh \
  --url "$GITHUB_RUNNER_URL" \
  --token "$GITHUB_RUNNER_TOKEN" \
  --name "$GITHUB_RUNNER_NAME" \
  --labels "$GITHUB_RUNNER_LABELS" \
  --runnergroup "$GITHUB_RUNNER_GROUP" \
  --work "_work" \
  --unattended \
  --replace

log "GitHub Actions runner configured successfully"
