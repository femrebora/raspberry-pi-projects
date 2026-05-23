#!/usr/bin/env bash
# Daily restic backup of Docker volumes + /etc + EXTRA_PATHS, with retention.
# Run under systemd via restic-backup.timer; the service unit sources env from
# /etc/default/restic-backup.

set -euo pipefail

PATHS=(
  /var/lib/docker/volumes
  /etc
)
# EXTRA_PATHS is space-separated in the env file; split safely.
if [[ -n "${EXTRA_PATHS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA=($EXTRA_PATHS)
  PATHS+=("${EXTRA[@]}")
fi

EXCLUDES=(
  --exclude='*.tmp'
  --exclude='*/lost+found'
  --exclude='/var/lib/docker/volumes/backingFsBlockDev'
)

: "${RESTIC_REPOSITORY:?must be set}"
: "${RESTIC_PASSWORD:?must be set}"

logger -t restic-backup "starting backup to $RESTIC_REPOSITORY"

restic backup "${PATHS[@]}" "${EXCLUDES[@]}" \
  --tag pi5 --tag auto \
  --host "$(hostname)"

restic forget --prune \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6

logger -t restic-backup "done"
