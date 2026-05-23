# 14 — Control panel (mini web dashboard)

A small, **single-page** web dashboard that ties every project in this repo together. Status, start/stop, log peek, Ollama model management, and per-project `.env` editor — works in any browser (laptop, desktop, or phone) over Tailscale or your LAN.

Built with FastAPI + HTMX. No JS build step, no React, no Node. ~250 lines total.

## Why bother

You will have 4–10 Docker Compose stacks running simultaneously. Running `docker compose ps` over SSH for each one is tedious from a phone. This panel:

- Shows every project's stack status at a glance.
- One-click start/stop per project.
- Reads each project's `.env.example`, lets you edit the live `.env` from the browser.
- Lists Ollama models, lets you pull a new one without SSHing in.
- Proxies the router's `/health` so you see provider availability.

It's deliberately *not* a Portainer/Cockpit replacement — those exist and are great. This one is bespoke for this repo's specific layout.

## Dependencies

| Thing | Why | How |
|---|---|---|
| Docker + Compose | runs the panel + manages other stacks | bootstrap script |
| Docker socket access | required to run `docker compose` for other projects | mounted into the panel container |
| Read/write to repo dir | reads compose files + edits `.env` files | mounted into the panel container |

## Setup

```bash
cd projects/14-control-panel
cp .env.example .env
# edit .env: choose PANEL_USER and PANEL_PASSWORD
docker compose up -d --build
```

Open `http://<pi-ip>:8000`. Log in with the credentials you set.

## Security

This panel has **full control of every container on your Pi** and can read every `.env`. Treat it accordingly:

- **Always** set strong `PANEL_USER` / `PANEL_PASSWORD`.
- The compose file binds to `0.0.0.0:8000` by default for LAN convenience. For anything reachable from the internet:
  - Change to `127.0.0.1:8000` and reverse-proxy via Caddy (project 02) with extra auth, **OR**
  - Reach it only over Tailscale (project 04).
- **Do not** expose this directly via Cloudflare Tunnel without an additional auth layer.

## What you see

**Dashboard view:** every project listed with green/red status, "Start", "Stop", "Logs", "Env" buttons.

**Env editor:** click "Env" → form with each variable from `.env.example` pre-filled with current value from `.env` (or empty). Submit writes the new `.env`. Restarts the stack on save.

**Ollama tab:** list installed models, pull a new one (e.g. `gemma3:1b`, `qwen2.5-coder:1.5b`). Free-text input + submit.

**Router tab:** mirrors `http://router:8088/health` so you see which providers are reachable.

## Resource cost

| | RAM | CPU |
|---|---|---|
| Panel idle | ~100 MB | 0 % |
| Docker socket polling | ~+10 MB | bursts |

## Production notes

- The panel runs `docker compose` from the **container**, which means the path you point it at must be the path **inside** the container. The Compose file mounts the repo root at `/repo`, and the panel auto-discovers `/repo/projects/*/docker-compose*.yml`. If you renamed the repo dir on disk, only the bind-mount source needs to change.
- The env editor never logs the values it writes. Passwords are masked in the form.
- For a richer experience: add [ttyd](https://github.com/tsl0922/ttyd) as a sibling container, mount the same auth proxy, get a web terminal. Out of scope for the included Compose file but a 10-line addition.
