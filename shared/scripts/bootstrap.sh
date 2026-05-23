#!/usr/bin/env bash
# Bootstrap a Raspberry Pi 5 (Pi OS Bookworm 64-bit) for the projects in this repo.
# Installs Docker + Compose plugin, sets up a 1 GB swap file, and applies a few
# kernel tweaks useful when running LLMs and long-lived containers.
#
# Idempotent: safe to re-run.
#
# Usage:  bash shared/scripts/bootstrap.sh

set -euo pipefail

log() { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[bootstrap]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[bootstrap]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "Run as your regular user (not root). The script will sudo when needed."
command -v sudo >/dev/null || die "sudo is required."

# --- 1. Base packages -------------------------------------------------------
log "Updating apt and installing base packages"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg lsb-release git jq htop \
  python3 python3-venv python3-pip \
  ufw fail2ban unattended-upgrades

# --- 2. Docker engine + compose plugin --------------------------------------
if ! command -v docker >/dev/null; then
  log "Installing Docker engine"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  warn "Added $USER to the 'docker' group. Log out and back in for it to take effect."
else
  log "Docker already installed: $(docker --version)"
fi

# --- 3. Swap file (1 GB) ----------------------------------------------------
# Pi OS ships with dphys-swapfile capped at 100 MB; LLM headroom needs more.
if [[ ! -f /swapfile ]]; then
  log "Creating 1 GB /swapfile"
  sudo fallocate -l 1G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile >/dev/null
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
else
  log "Swap file already present"
fi

# Lower swappiness so we use RAM first, swap only as a safety net.
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-pi-swappiness.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/99-pi-swappiness.conf >/dev/null

# --- 4. Time sync (important for TLS) ---------------------------------------
sudo systemctl enable --now systemd-timesyncd

# --- 5. unattended-upgrades default config ---------------------------------
# Apply security updates automatically; reboots are still manual.
sudo dpkg-reconfigure -f noninteractive unattended-upgrades || true

log "Done."
log ""
log "Next steps:"
log "  1. exit + ssh back in, so the docker group takes effect"
log "  2. sudo bash projects/11-security-baseline/bootstrap.sh   # ufw + fail2ban"
log "  3. Pick a project from README.md"
