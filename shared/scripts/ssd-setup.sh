#!/usr/bin/env bash
# Optional helper: mount a USB SSD as a separate /mnt/ssd volume.
# Use this if you boot from microSD but want Docker volumes / large files on SSD.
# If you already boot from SSD (recommended — see docs/os-install.md), skip this.
#
# Usage: sudo bash shared/scripts/ssd-setup.sh /dev/sda1

set -euo pipefail

DEV="${1:-}"
MOUNT="/mnt/ssd"

[[ -n "$DEV" ]] || { echo "Usage: $0 /dev/sdXN" >&2; exit 1; }
[[ -b "$DEV" ]] || { echo "$DEV is not a block device." >&2; exit 1; }

UUID=$(blkid -s UUID -o value "$DEV") || { echo "Failed to read UUID for $DEV" >&2; exit 1; }
FSTYPE=$(blkid -s TYPE -o value "$DEV")

echo "Device $DEV  UUID=$UUID  type=$FSTYPE"

mkdir -p "$MOUNT"

if ! grep -q "$UUID" /etc/fstab; then
  echo "UUID=$UUID  $MOUNT  $FSTYPE  defaults,noatime,nofail  0  2" >> /etc/fstab
  echo "Added to /etc/fstab"
fi

mount -a
echo "Mounted:"
df -h "$MOUNT"

echo
echo "Done. To put Docker's data root on the SSD:"
echo "  sudo systemctl stop docker"
echo "  sudo rsync -aHAX /var/lib/docker/ $MOUNT/docker/"
echo "  echo '{\"data-root\":\"$MOUNT/docker\"}' | sudo tee /etc/docker/daemon.json"
echo "  sudo systemctl start docker"
