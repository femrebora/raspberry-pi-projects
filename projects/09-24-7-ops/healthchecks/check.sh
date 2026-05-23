#!/usr/bin/env bash
# Health probe: returns 0 if docker responds, non-zero otherwise.
# Used by pi-watchdog.sh. Bumps a fail counter and reboots after N consecutive failures.
#
# Install:
#   sudo install -m 0755 projects/09-24-7-ops/healthchecks/check.sh /usr/local/sbin/pi-watchdog.sh

set -euo pipefail

STATE_DIR="/var/lib/pi-watchdog"
FAILS_FILE="$STATE_DIR/fails"
THRESHOLD="${THRESHOLD:-3}"

mkdir -p "$STATE_DIR"
[[ -f "$FAILS_FILE" ]] || echo 0 > "$FAILS_FILE"

if timeout 40 docker ps >/dev/null 2>&1; then
  echo 0 > "$FAILS_FILE"
  logger -t pi-watchdog "docker ok"
  exit 0
fi

CURRENT=$(($(cat "$FAILS_FILE") + 1))
echo "$CURRENT" > "$FAILS_FILE"
logger -t pi-watchdog "docker failed (count=$CURRENT/$THRESHOLD)"

if (( CURRENT >= THRESHOLD )); then
  logger -t pi-watchdog "threshold reached — rebooting"
  echo 0 > "$FAILS_FILE"
  /sbin/reboot
fi
