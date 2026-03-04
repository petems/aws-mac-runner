#!/bin/bash
# Install common CI/CD tools via Homebrew + pre-built binaries
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

log "Installing Homebrew packages: ${BREW_PACKAGES[*]}"
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    log "  $pkg: already installed"
  else
    log "  $pkg: installing..."
    brew install "$pkg" --quiet
  fi
done

# Install SwiftLint from pre-built binary (Homebrew requires full Xcode.app to
# compile from source, but the .pkg from GitHub releases works with just CLI tools)
SWIFTLINT_VERSION="${SWIFTLINT_VERSION:-0.63.2}"
if command -v swiftlint &>/dev/null; then
  log "  swiftlint: already installed ($(swiftlint version))"
else
  log "  swiftlint: installing v${SWIFTLINT_VERSION} from pre-built binary..."
  curl -fsSL -o /tmp/SwiftLint.pkg \
    "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/SwiftLint.pkg"
  sudo installer -pkg /tmp/SwiftLint.pkg -target /
  rm -f /tmp/SwiftLint.pkg
  log "  swiftlint: installed $(swiftlint version)"
fi

log "Common tools installation complete"
log "Installed versions:"
log "  jq: $(jq --version 2>/dev/null || echo 'n/a')"
log "  gh: $(gh --version 2>/dev/null | head -1 || echo 'n/a')"
log "  cmake: $(cmake --version 2>/dev/null | head -1 || echo 'n/a')"
log "  swiftlint: $(swiftlint version 2>/dev/null || echo 'n/a')"
log "  cocoapods: $(pod --version 2>/dev/null || echo 'n/a')"
log "  fastlane: $(fastlane --version 2>/dev/null | head -1 || echo 'n/a')"
