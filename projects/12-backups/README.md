# 12 — Backups with restic

[`restic`](https://restic.net) is a fast, encrypted, deduplicating backup tool. We back up Docker volumes (Caddy certs, Uptime Kuma history, Open WebUI users, etc.) and any data you care about, on a daily timer, to a remote of your choice.

## Backup targets (pick one)

| Where | Free tier (May 2026) | URL form |
|---|---|---|
| **Backblaze B2** | First 10 GB free, then $0.006/GB/mo | `b2:bucket/path` |
| Local USB drive | Costs you the drive only | `/mnt/backup-drive/restic` |
| Hetzner Storage Box | €1.20/100GB/mo (cheap, not free) | `sftp:user@hbox:/restic` |
| AWS S3 / Wasabi / R2 | Various | `s3:s3.amazonaws.com/bucket/path` |

The included config defaults to a local drive — change `RESTIC_REPOSITORY` in `.env` for B2 etc.

## Setup

```bash
sudo apt install -y restic
cd projects/12-backups
cp .env.example .env
$EDITOR .env                  # set RESTIC_REPOSITORY and RESTIC_PASSWORD

# initialise the repository (one-time)
sudo --preserve-env=RESTIC_REPOSITORY,RESTIC_PASSWORD restic init

# install the systemd service + timer
sudo install -m 0755 restic-backup.sh /usr/local/sbin/
sudo install -m 0644 systemd/restic-backup.service /etc/systemd/system/
sudo install -m 0644 systemd/restic-backup.timer   /etc/systemd/system/
sudo install -m 0644 .env /etc/default/restic-backup    # service reads env from here
sudo chmod 600 /etc/default/restic-backup
sudo systemctl daemon-reload
sudo systemctl enable --now restic-backup.timer
```

Run a backup now to verify:

```bash
sudo systemctl start restic-backup.service
journalctl -u restic-backup -f
```

## What it backs up

`restic-backup.sh` snapshots:

- `/var/lib/docker/volumes/` — every named Docker volume
- `/etc` — your config (sshd, ufw, fail2ban, etc.)
- Anything you list in `EXTRA_PATHS` (e.g., `/home/$USER/sites`)

It also prunes old snapshots (keeps last 7 daily, 4 weekly, 6 monthly).

## Restore drill

You should do this **once** to know it works. Pick a snapshot:

```bash
sudo --preserve-env=RESTIC_REPOSITORY,RESTIC_PASSWORD restic snapshots
sudo --preserve-env=RESTIC_REPOSITORY,RESTIC_PASSWORD \
  restic restore <snapshot-id> --target /tmp/restore-test
```

…then poke around `/tmp/restore-test/` and check the files match.

## B2 setup

1. Sign up at <https://www.backblaze.com>, **App Keys** → **Add a New Application Key**.
2. Put the keyID and key into `.env`:
   ```
   B2_ACCOUNT_ID=xxxx
   B2_ACCOUNT_KEY=xxxx
   RESTIC_REPOSITORY=b2:your-bucket-name:pi5
   RESTIC_PASSWORD=long-random-string
   ```
3. `restic init` (no other change required).

## Production notes

- **Test the restore.** A backup you've never restored is just a hope.
- The `RESTIC_PASSWORD` is the encryption key. Lose it = lose your backups forever. Store it in a password manager *outside* the Pi.
- If you back up to the same SSD that holds your data, you have backup but not disaster recovery. Pair local + remote for both speed and safety.
