#!/bin/bash
# Ensure Homebrew is installed and up to date
# AWS macOS AMIs come with Homebrew pre-installed
set -euo pipefail

LOG_PREFIX="[homebrew]"

log() {
  echo "$LOG_PREFIX $*"
}

# Homebrew location on Apple Silicon
BREW_PATH="/opt/homebrew/bin/brew"

if [[ -x "$BREW_PATH" ]]; then
  log "Homebrew found at $BREW_PATH"

  # Add to PATH if not already present
  eval "$("$BREW_PATH" shellenv)"

  log "Updating Homebrew..."
  brew update --quiet
  log "Homebrew version: $(brew --version | head -1)"
else
  log "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  log "Homebrew installed: $(brew --version | head -1)"
fi

# Ensure brew is in shell profile for future sessions
SHELL_PROFILE="$HOME/.zprofile"
if ! grep -q 'brew shellenv' "$SHELL_PROFILE" 2>/dev/null; then
  # shellcheck disable=SC2016
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_PROFILE"
  log "Added Homebrew to $SHELL_PROFILE"
fi

log "Homebrew setup complete"
