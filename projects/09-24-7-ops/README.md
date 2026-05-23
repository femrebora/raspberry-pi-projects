# 09 — 24/7 operations: systemd, restart policies, watchdog

The recipes that make every other project survive reboots, kernel updates, and the occasional Pi freeze.

## What's in here

| File | What it does |
|---|---|
| `systemd/docker-compose@.service` | A template unit so any Compose project can be enabled with one command |
| `systemd/pi-watchdog.service` + `.timer` | Tiny periodic check that reboots the Pi if Docker becomes unresponsive |
| `healthchecks/check.sh` | Health-checks every Compose project's `restart: unless-stopped` container; pings [healthchecks.io](https://healthchecks.io) (free tier) so you know if your Pi is alive |
| `docker-compose.override.example.yml` | Snippet you can drop into any project to pin log size + add resource limits |

## Dependencies

| Thing | Why | How to get it |
|---|---|---|
| Docker | for restart-policies + the watchdog probe | bootstrap script |
| `systemctl` | unit management | preinstalled on Pi OS |
| (Optional) Healthchecks.io account | external uptime ping; free tier is 20 monitors | <https://healthchecks.io> |
| (Optional) Pi 5 hardware watchdog | survives a fully locked kernel | enabled by adding `dtparam=watchdog=on` to `/boot/firmware/config.txt`, then `sudo apt install watchdog` |

## Enable a Compose project at boot

```bash
sudo cp projects/09-24-7-ops/systemd/docker-compose@.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable any project — the path after @ is the Compose directory, escaped.
# Example: enable the static site project
sudo systemctl enable --now \
  "docker-compose@$(systemd-escape -p $PWD/projects/01-static-site-caddy).service"
```

The unit runs `docker compose up -d` at boot and `docker compose down` on shutdown. Combined with `restart: unless-stopped` in each Compose file, your services come back even after a kernel update reboot.

## Watchdog

`pi-watchdog.service` runs every 5 minutes (via the matching `.timer`) and:

1. Pings `docker ps`. If it times out (40 s), it logs and exits.
2. If it fails 3 times in a row (state file at `/var/lib/pi-watchdog/fails`), it triggers a soft reboot.

```bash
sudo cp projects/09-24-7-ops/systemd/pi-watchdog.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pi-watchdog.timer
```

For a *hardware* watchdog (catches a fully locked kernel), see "Optional" above.

## Healthchecks.io pings

Create a free check at <https://healthchecks.io>, copy the URL, then:

```bash
# crontab -e
*/5 * * * * curl -fsS --retry 3 -o /dev/null https://hc-ping.com/<your-uuid>
```

If the Pi stops pinging for >10 min, you get an email/SMS/whatever you configured.

## Log size caps (your future self will thank you)

Without limits, Docker JSON logs can fill the SSD. Append `docker-compose.override.example.yml` to any project's directory or add to each service:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

## Resource cost

Negligible — everything here is < 10 MB RAM and zero CPU at idle.
