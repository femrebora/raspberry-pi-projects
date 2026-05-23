# 11 — Security baseline

The non-negotiable first pass for any Pi that's reachable from anything other than your LAN — and a smart default even if it's not.

## What `bootstrap.sh` does

1. Installs and enables `ufw` (firewall):
   - Default deny inbound, allow outbound.
   - Allows SSH (22), HTTP (80), HTTPS (443).
   - Allows the Tailscale interface (`tailscale0`) if present.
2. Installs and enables `fail2ban` with a Pi-tuned `jail.local`:
   - Bans IPs after 5 failed SSH attempts.
   - 1 h ban duration, doubled on repeat.
3. Configures `unattended-upgrades` to auto-apply security patches daily.
4. Hardens `sshd_config`:
   - Disables root login.
   - Disables password auth (key-only).
   - Sets `MaxAuthTries 3`.
5. Drops a `logrotate` config for Docker JSON logs.

It's idempotent: re-run any time.

```bash
sudo bash projects/11-security-baseline/bootstrap.sh
```

## Watchtower (Docker auto-update)

Watchtower checks the registry for new image tags daily and recreates running containers with the new image — minimal-effort patching for everything in this repo.

```bash
docker compose -f projects/11-security-baseline/docker-compose.watchtower.yml up -d
```

Defaults: poll every 24 h, only update images that already have the same tag (no major-version surprises), self-update Watchtower itself, clean up old images.

If you'd rather review updates before they apply, set `WATCHTOWER_MONITOR_ONLY=true` and check the logs.

## Dependencies

| Thing | Why | How |
|---|---|---|
| `ufw`, `fail2ban`, `unattended-upgrades` | the script installs them | `apt` |
| Docker | for Watchtower | bootstrap script in `shared/scripts/` |

## Verify

```bash
sudo ufw status verbose
sudo fail2ban-client status sshd
systemctl status unattended-upgrades
sudo less /etc/ssh/sshd_config.d/10-hardening.conf
```

## Production notes

- **Make sure your SSH key works *before* running the script.** It disables password auth — if you've never logged in with a key you'll lock yourself out. Always test in a second SSH session.
- If you also run Tailscale (project 04), this script will detect `tailscaled` and allow that interface — so SSH over Tailscale keeps working even if you tighten further (e.g., dropping port-22 from `ufw`).
- Watchtower will pull `:latest` automatically. If you want pinned versions (recommended for production), change tags in each Compose file (e.g., `caddy:2.8.4-alpine`) and Watchtower will only update within that tag.
