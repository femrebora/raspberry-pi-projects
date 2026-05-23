#!/usr/bin/env bash
# Install Tailscale on Pi OS / Debian.
# Run with sudo. Idempotent.

set -euo pipefail

if command -v tailscale >/dev/null; then
  echo "Tailscale already installed: $(tailscale version | head -n1)"
  exit 0
fi

curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled

echo
echo "Done. Now run:  sudo tailscale up --ssh"
echo "Then follow the URL printed to authenticate."
