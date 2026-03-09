#!/bin/bash
# Bootstrap Puppet agent on macOS and apply the runner role
# Runs as root from user_data; puppet apply runs site-modules.
set -euo pipefail

LOG_PREFIX="[puppet-bootstrap]"
LOG_FILE="/var/log/mac-runner-puppet-bootstrap.log"

log() {
  echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"
}

PUPPET_DIR="/etc/puppetlabs/code"
PUPPET_BIN="/opt/puppetlabs/bin"

# --- Step 1: Install Puppet agent from official .dmg ---
if [[ -x "${PUPPET_BIN}/puppet" ]]; then
  log "Puppet agent already installed: $(${PUPPET_BIN}/puppet --version)"
else
  log "Installing Puppet 8 agent..."
  PUPPET_DMG="/tmp/puppet-agent.dmg"
  # Detect architecture for correct package
  ARCH="$(uname -m)"
  case "$ARCH" in
    arm64)
      PUPPET_DMG_URL="https://apt.puppet.com/puppet8/puppet-agent-latest-macos-15-arm64.dmg"
      ;;
    x86_64)
      PUPPET_DMG_URL="https://apt.puppet.com/puppet8/puppet-agent-latest-macos-15-x86_64.dmg"
      ;;
    *)
      log "ERROR: Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  curl -fsSL -o "$PUPPET_DMG" "$PUPPET_DMG_URL"
  hdiutil attach "$PUPPET_DMG" -nobrowse -quiet
  MOUNT_POINT=$(hdiutil info | grep -m1 '/Volumes/puppet' | awk '{print $NF}')
  sudo installer -pkg "${MOUNT_POINT}/"*.pkg -target /
  hdiutil detach "$MOUNT_POINT" -quiet
  rm -f "$PUPPET_DMG"
  log "Puppet agent installed: $(${PUPPET_BIN}/puppet --version)"
fi

export PATH="${PUPPET_BIN}:${PATH}"

# --- Step 2: Install r10k and community modules ---
log "Installing r10k..."
${PUPPET_BIN}/gem install r10k --no-document 2>/dev/null || true

PUPPETFILE_DIR="/tmp/mac-runner-puppet"
log "Running r10k puppetfile install..."
cd "$PUPPETFILE_DIR"
${PUPPET_BIN}/r10k puppetfile install --verbose --moduledir "${PUPPET_DIR}/modules"

# --- Step 3: Write instance.yaml from environment variables ---
log "Writing instance Hiera data..."
HIERA_DATA_DIR="${PUPPET_DIR}/data"
mkdir -p "$HIERA_DATA_DIR"

cat > "${HIERA_DATA_DIR}/instance.yaml" << INSTANCE_YAML
---
profile::mac_runner::runner_install::github_runner_url: "${GITHUB_RUNNER_URL}"
profile::mac_runner::runner_install::github_runner_token: "${GITHUB_RUNNER_TOKEN}"
profile::mac_runner::runner_install::github_runner_name: "${GITHUB_RUNNER_NAME}"
profile::mac_runner::runner_install::github_runner_labels: "${GITHUB_RUNNER_LABELS}"
profile::mac_runner::runner_install::github_runner_group: "${GITHUB_RUNNER_GROUP}"
INSTANCE_YAML

# --- Step 4: Copy site-modules and hiera config ---
log "Deploying site-modules and Hiera configuration..."
cp -R "${PUPPETFILE_DIR}/site-modules" "${PUPPET_DIR}/"
cp "${PUPPETFILE_DIR}/hiera.yaml" "${PUPPET_DIR}/hiera.yaml"
cp "${PUPPETFILE_DIR}/data/common.yaml" "${HIERA_DATA_DIR}/common.yaml"

# --- Step 5: Apply the role ---
log "Running puppet apply..."
${PUPPET_BIN}/puppet apply \
  --modulepath "${PUPPET_DIR}/site-modules:${PUPPET_DIR}/modules" \
  --hiera_config "${PUPPET_DIR}/hiera.yaml" \
  --verbose \
  --show_diff \
  -e 'include role::github_actions_mac_runner' 2>&1 | tee -a "$LOG_FILE"

log "Puppet bootstrap complete!"
