# 10 — Monitoring with Uptime Kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a self-hosted uptime + status dashboard. Beautiful UI, dead-simple to run, free. You point it at every HTTP endpoint, port, ping, DNS record, Docker container, etc., and it tells you what's up.

Pairs perfectly with [project 09](../09-24-7-ops/) — Uptime Kuma watches *from the Pi*; project 09's `healthchecks.io` ping watches *the Pi itself* from the outside.

## Setup

```bash
cd projects/10-monitoring-uptime
docker compose up -d
```

Open `http://<pi-ip>:3001`. The first sign-up becomes admin.

## What to monitor

A starter set for this repo:

| Monitor type | Target |
|---|---|
| HTTP(s) | `https://yourdomain.com` (project 01/02) |
| HTTP(s) keyword | `http://localhost:3000` — keyword `"Open WebUI"` (project 05) |
| TCP | `localhost:11434` (Ollama) |
| HTTP | `http://localhost:8088/health` (project 07 router) |
| HTTP | `http://localhost:8090/health` (project 08 hybrid) |
| Docker container | `cloudflared`, `tailscale`, etc. — needs Docker socket mounted |
| Ping | `1.1.1.1` (so you know if your internet died) |

## Notifications

Settings → Notifications. Supports email (SMTP), Telegram, Discord, ntfy, webhook, Slack, and ~80 others. The Telegram bot route is the quickest.

## Resource cost

| | RAM | CPU |
|---|---|---|
| Uptime Kuma | ~150 MB | <1 % |

Stores history in SQLite under the `kuma_data` volume — back it up via project 12.

## Production notes

- Bind to `127.0.0.1:3001` and reverse-proxy via Caddy (project 02) if you don't want the dashboard publicly reachable.
- Don't monitor every endpoint every 20 seconds — defaults are fine. Tighter intervals burn battery if you're on a UPS.
- If you want a public status page (e.g., `status.yourdomain.com`), Uptime Kuma has one built in: **Status Pages** → **Add New Status Page**.
