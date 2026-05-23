#!/usr/bin/env bash
# Security baseline for Raspberry Pi 5 (Pi OS Bookworm). Run with sudo. Idempotent.
#
# What it does:
#   - ufw   : default-deny inbound, allow 22/80/443 + tailscale0 if present
#   - fail2ban: SSH bans after 5 failed attempts
#   - unattended-upgrades: daily security patches
#   - sshd  : disable root login, disable password auth (KEY ONLY!), MaxAuthTries 3
#   - logrotate snippet for Docker

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

log() { printf '\033[1;34m[sec-base]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[sec-base]\033[0m %s\n' "$*" >&2; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 1. packages ------------------------------------------------------------
log "Installing ufw, fail2ban, unattended-upgrades"
apt-get update -qq
apt-get install -y --no-install-recommends ufw fail2ban unattended-upgrades

# --- 2. ufw -----------------------------------------------------------------
log "Configuring ufw"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment "ssh"
ufw allow 80/tcp comment "http"
ufw allow 443/tcp comment "https"
if ip link show tailscale0 >/dev/null 2>&1; then
  ufw allow in on tailscale0
  log "Allowed tailscale0 (private mesh)"
fi
ufw --force enable
ufw status verbose

# --- 3. fail2ban ------------------------------------------------------------
log "Configuring fail2ban (jail.local)"
install -m 0644 "$REPO_DIR/fail2ban/jail.local" /etc/fail2ban/jail.local
systemctl enable --now fail2ban
systemctl restart fail2ban

# --- 4. unattended-upgrades -------------------------------------------------
log "Enabling daily security upgrades"
dpkg-reconfigure -f noninteractive unattended-upgrades || true
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# --- 5. sshd hardening (KEY ONLY — must already have key working) ----------
log "Hardening sshd"
mkdir -p /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
MaxAuthTries 3
LoginGraceTime 20
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
warn "Password SSH disabled. Make sure your key works (test in a second terminal!)"
systemctl reload ssh

# --- 6. logrotate for Docker -----------------------------------------------
log "Installing Docker logrotate config"
install -m 0644 "$REPO_DIR/logrotate/docker.conf" /etc/logrotate.d/docker-containers

log "Done."
log "Verify:"
log "  sudo ufw status verbose"
log "  sudo fail2ban-client status sshd"
log "  systemctl status unattended-upgrades"
