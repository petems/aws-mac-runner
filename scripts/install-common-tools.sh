#!/bin/bash
# Install common CI/CD tools via Homebrew
set -euo pipefail

LOG_PREFIX="[common-tools]"

log() {
  echo "$LOG_PREFIX $*"
}

# Ensure brew is available
eval "$(/opt/homebrew/bin/brew shellenv)"

BREW_PACKAGES=(
  jq
  gh
  cmake
  cocoapods
  fastlane
)

# swiftlint requires full Xcode.app to build from source — install separately
# only if Xcode.app is present (not just CLI tools)
OPTIONAL_BREW_PACKAGES=(
  swiftlint
)

log "Installing Homebrew packages: ${BREW_PACKAGES[*]}"
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    log "  $pkg: already installed"
  else
    log "  $pkg: installing..."
    brew install "$pkg" --quiet
  fi
done

# Install optional packages that may require full Xcode.app
for pkg in "${OPTIONAL_BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    log "  $pkg: already installed"
  else
    log "  $pkg: installing (optional, may fail without full Xcode.app)..."
    brew install "$pkg" --quiet || log "  $pkg: skipped (requires full Xcode.app)"
  fi
done

log "Common tools installation complete"
log "Installed versions:"
log "  jq: $(jq --version 2>/dev/null || echo 'n/a')"
log "  gh: $(gh --version 2>/dev/null | head -1 || echo 'n/a')"
log "  cmake: $(cmake --version 2>/dev/null | head -1 || echo 'n/a')"
log "  swiftlint: $(swiftlint version 2>/dev/null || echo 'n/a')"
log "  cocoapods: $(pod --version 2>/dev/null || echo 'n/a')"
log "  fastlane: $(fastlane --version 2>/dev/null | head -1 || echo 'n/a')"
