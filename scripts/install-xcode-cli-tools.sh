#!/bin/bash
# Ensure Xcode Command Line Tools are installed
# AWS macOS AMIs typically have these pre-installed
set -euo pipefail

LOG_PREFIX="[xcode-cli]"

log() {
  echo "$LOG_PREFIX $*"
}

# Check if CLI tools are already installed
if xcode-select -p &>/dev/null; then
  log "Xcode CLI Tools already installed at: $(xcode-select -p)"
  log "Version: $(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | grep version || echo 'unknown')"
else
  log "Installing Xcode Command Line Tools..."

  # Create the placeholder file that triggers the install
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

  # Find the CLI tools package
  PROD=$(softwareupdate -l 2>/dev/null | grep -B 1 "Command Line Tools" | grep -o 'Command Line Tools.*' | head -1)

  if [[ -n "$PROD" ]]; then
    log "Installing: $PROD"
    softwareupdate -i "$PROD" --verbose
  else
    log "ERROR: Could not find Command Line Tools in software updates"
    exit 1
  fi

  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  log "Xcode CLI Tools installed"
fi

# Accept license if needed
sudo xcodebuild -license accept 2>/dev/null || true

log "Xcode CLI Tools setup complete"
