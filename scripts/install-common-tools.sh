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

GEM_PACKAGES=(
  cocoapods
  fastlane
)

log "Installing Ruby gems: ${GEM_PACKAGES[*]}"
for gem in "${GEM_PACKAGES[@]}"; do
  if gem list -i "$gem" &>/dev/null; then
    log "  $gem: already installed"
  else
    log "  $gem: installing..."
    gem install "$gem" --no-document
  fi
done

# SwiftLint via Homebrew
if brew list swiftlint &>/dev/null; then
  log "swiftlint: already installed"
else
  log "swiftlint: installing..."
  brew install swiftlint --quiet
fi

log "Common tools installation complete"
log "Installed versions:"
log "  jq: $(jq --version 2>/dev/null || echo 'n/a')"
log "  gh: $(gh --version 2>/dev/null | head -1 || echo 'n/a')"
log "  cmake: $(cmake --version 2>/dev/null | head -1 || echo 'n/a')"
log "  swiftlint: $(swiftlint version 2>/dev/null || echo 'n/a')"
log "  cocoapods: $(pod --version 2>/dev/null || echo 'n/a')"
log "  fastlane: $(fastlane --version 2>/dev/null | head -1 || echo 'n/a')"
