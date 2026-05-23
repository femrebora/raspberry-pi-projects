# raspberry-pi-projects

[![lint](https://github.com/femrebora/raspberry-pi-projects/actions/workflows/lint.yml/badge.svg)](https://github.com/femrebora/raspberry-pi-projects/actions/workflows/lint.yml)
[![compose-validate](https://github.com/femrebora/raspberry-pi-projects/actions/workflows/compose-validate.yml/badge.svg)](https://github.com/femrebora/raspberry-pi-projects/actions/workflows/compose-validate.yml)
[![license](https://img.shields.io/badge/license-MIT-A3E635)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205%20%7C%20ARM64-C7053D?logo=raspberrypi&logoColor=white)](docs/hardware-setup.md)
[![python](https://img.shields.io/badge/python-3.10+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![web](https://img.shields.io/badge/web-Caddy%20%7C%20FastAPI-009688?logo=fastapi&logoColor=white)](#whats-inside)
[![LLM](https://img.shields.io/badge/local%20LLM-Ollama%20%7C%20llama.cpp-000000?logo=ollama&logoColor=white)](projects/05-ollama-local-llm)
[![models](https://img.shields.io/badge/cloud%20models-Claude%20%7C%20Gemini%20%7C%20DeepSeek%20%7C%20Groq%20%7C%20OpenRouter%20%7C%20Cerebras-7C3AED)](projects/13-ai-cli-toolkit)
[![tunnel](https://img.shields.io/badge/tunnel-Cloudflare%20%7C%20Tailscale-F38020?logo=cloudflare&logoColor=white)](projects/03-cloudflare-tunnel)
[![status](https://img.shields.io/badge/status-active-A3E635)](#)

Production-ready starter projects for a **Raspberry Pi 5 (8 GB)** covering self-hosted websites, local + cloud LLMs, secure public exposure, an AI-CLI toolkit you reach from your phone, and a small web control panel that ties it all together. Each project is clone-and-run with Docker Compose where it fits, and every README lists the exact dependencies, sign-up steps, and resource cost.

## Quick install (interactive TUI)

On a fresh Pi 5 with Raspberry Pi OS 64-bit:

```bash
git clone https://github.com/femrebora/raspberry-pi-projects.git
cd raspberry-pi-projects
bash install.sh
```

A whiptail TUI walks you through:

1. Base bootstrap (Docker + swap + kernel tweaks)
2. Security baseline (`ufw` + `fail2ban` + auto-updates)
3. Project checklist — pick which of the 14 to deploy
4. Per-project key prompts (Cloudflare token, free-LLM API keys, etc.)
5. Brings up every selected Compose stack, prints final URLs

The default selection enables the **control panel (14)**, **Ollama (05)**, **free-LLM router (07)**, and **AI CLI toolkit (13)** — i.e. once it finishes you can browse to `http://<pi-ip>:8000`, log in, and manage everything from a web UI.

Re-run `install.sh` any time to add more projects, rotate keys, or repair a stack — it's idempotent.

For step-by-step manual setup instead, see [`docs/os-install.md`](docs/os-install.md).

## What's inside

| # | Project | What it does | Stack |
|---|---|---|---|
| [01](projects/01-static-site-caddy) | Static site with auto-HTTPS | Personal site / docs / portfolio | Caddy + Docker |
| [02](projects/02-dynamic-site-fastapi) | Dynamic web app | API or full app behind a reverse proxy | FastAPI + Caddy + Docker |
| [03](projects/03-cloudflare-tunnel) | Free public exposure | Reach the Pi from the internet without port-forwarding | `cloudflared` |
| [04](projects/04-tailscale-private) | Private remote access | Encrypted mesh from any device | Tailscale |
| [05](projects/05-ollama-local-llm) | Local LLM, easy mode | Chat with an LLM running on the Pi itself | Ollama + Open WebUI |
| [06](projects/06-llamacpp-local-llm) | Local LLM, fast mode | 10–20 % more tok/s than Ollama; LocalAI / llamafile pointers | llama.cpp |
| [07](projects/07-free-llm-api-router) | Free cloud-LLM router | OpenAI-compatible proxy that fails over across free tiers | Python + FastAPI |
| [08](projects/08-hybrid-llm-fallback) | Hybrid LLM app | Try local first, fall back to free cloud APIs under load | Python |
| [09](projects/09-24-7-ops) | 24/7 operations | systemd units, restart policies, watchdog | systemd + Docker |
| [10](projects/10-monitoring-uptime) | Monitoring | Uptime + service health dashboard | Uptime Kuma |
| [11](projects/11-security-baseline) | Security baseline | `ufw` + `fail2ban` + unattended-upgrades + Watchtower | Shell + Docker |
| [12](projects/12-backups) | Backups | Encrypted off-site backups | `restic` + systemd timer |
| [13](projects/13-ai-cli-toolkit) | AI CLI toolkit | Claude Code, Gemini CLI, Codex CLI, Aider, `llm`, `sgpt` — SSH in from your phone and use them all | Shell + Node + pipx |
| [14](projects/14-control-panel) | Mini web dashboard | One page to start/stop every stack, edit `.env`, manage Ollama, check the router | FastAPI + HTMX |

## Docs

- [`docs/hardware-setup.md`](docs/hardware-setup.md) — cooler, SSD, PSU, the works
- [`docs/os-install.md`](docs/os-install.md) — flash, SSH hardening, move-to-SSD
- [`docs/free-domain-dns.md`](docs/free-domain-dns.md) — DuckDNS / Cloudflare quick tunnels / Tailscale MagicDNS
- [`docs/remote-access-from-phone.md`](docs/remote-access-from-phone.md) — Tailscale + SSH client + control panel from iOS / Android
- [`docs/glossary.md`](docs/glossary.md) — terms in this repo, kept short
- [`projects/05-ollama-local-llm/benchmarks.md`](projects/05-ollama-local-llm/benchmarks.md) — measured tok/s for every recommended Ollama model
- [`projects/05-ollama-local-llm/alt-models.md`](projects/05-ollama-local-llm/alt-models.md) — best small models by task (coding, reasoning, vision, multilingual, embeddings)

## Start here

1. [`docs/hardware-setup.md`](docs/hardware-setup.md) — what to buy / wire up.
2. [`docs/os-install.md`](docs/os-install.md) — Pi OS 64-bit, SSH, move to SSD.
3. `bash shared/scripts/bootstrap.sh` — Docker, swap, kernel tweaks.
4. `sudo bash projects/11-security-baseline/bootstrap.sh` — firewall, fail2ban, auto-updates.
5. Pick a project and follow its README.

## Recommended order for a fresh Pi

```
docs/hardware-setup.md       →  buy / wire up
docs/os-install.md           →  flash, SSH in
shared/scripts/bootstrap.sh  →  base packages + Docker
projects/11-security-baseline  →  ufw, fail2ban, auto-updates
projects/04-tailscale-private  →  stop using the LAN cable
projects/13-ai-cli-toolkit     →  Claude/Gemini/Aider/llm on the Pi
projects/05-ollama-local-llm   →  prove the Pi can run a model
projects/07-free-llm-api-router  →  free cloud-LLM safety net
projects/01-static-site-caddy  →  put something on the internet
projects/03-cloudflare-tunnel  →  make it reachable publicly
projects/14-control-panel      →  one dashboard for everything
projects/09-24-7-ops           →  survive reboots
projects/10-monitoring-uptime  →  know when it dies
projects/12-backups            →  recover when it dies
```

## Free-LLM-API key sign-ups (none cost money, none require a credit card)

| Provider | Free tier (May 2026) | Get a key |
|---|---|---|
| Google AI Studio (Gemini) | 1 500 req/day, 1 M-token context | <https://aistudio.google.com/apikey> |
| Groq | 30 req/min, 1 000 req/day, ~315 tok/s | <https://console.groq.com/keys> |
| Cerebras | 1 000 000 tokens/day, 8 K context cap | <https://cloud.cerebras.ai> |
| OpenRouter | Dozens of `:free` models, varies | <https://openrouter.ai/keys> |
| Hugging Face Inference | Generous shared pool, slower | <https://huggingface.co/settings/tokens> |
| DeepSeek (effectively free, $0.07/M cached input) | Pay-as-you-go, no minimum | <https://platform.deepseek.com> |
| Anthropic (Claude Code CLI) | Pay-as-you-go; Claude Pro $20/mo includes CLI | <https://console.anthropic.com/settings/keys> |
| OpenAI (Codex CLI, sgpt) | Pay-as-you-go from $0.15/M (4o-mini) | <https://platform.openai.com/api-keys> |

> No keys are committed to this repo. Every project has a `.env.example`; copy it to `.env` and paste in your own keys. The router project (07) lets you stack the free ones so you rarely hit a limit. The control panel (14) gives you a web form to edit each `.env`.

## Consolidated env-var reference

| Var | Used by | Where to set it |
|---|---|---|
| `SITE_DOMAIN` | projects 01, 02 | `projects/0{1,2}-*/.env` |
| `CF_TUNNEL_TOKEN` | project 03 | `projects/03-cloudflare-tunnel/.env` |
| `TAILSCALE_AUTHKEY` | project 04 (Docker mode) | `projects/04-tailscale-private/.env` |
| `GROQ_API_KEY` | router (07), hybrid (08), CLI toolkit (13) | provider `.env` + `~/.ai_keys` |
| `GEMINI_API_KEY` / `GOOGLE_API_KEY` | 07, 13 | `.env` + `~/.ai_keys` |
| `CEREBRAS_API_KEY` | 07 | `.env` |
| `OPENROUTER_API_KEY` | 07, 13 | `.env` + `~/.ai_keys` |
| `HF_API_KEY` | 07 | `.env` |
| `ANTHROPIC_API_KEY` *or* `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code (13) | `~/.ai_keys` |
| `OPENAI_API_KEY` | Codex CLI, sgpt, Aider (13) | `~/.ai_keys` |
| `DEEPSEEK_API_KEY` | Aider, `llm` (13) | `~/.ai_keys` |
| `OLLAMA_URL`, `OLLAMA_MODEL` | hybrid (08), control panel (14) | their `.env` |
| `ROUTER_URL` | hybrid (08), control panel (14) | their `.env` |
| `PANEL_USER`, `PANEL_PASSWORD` | control panel (14) | `projects/14-control-panel/.env` |
| `RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `B2_*`, `AWS_*` | backups (12) | `projects/12-backups/.env` and `/etc/default/restic-backup` |
| `PROVIDER_ORDER`, `REQUEST_TIMEOUT` | router (07) | `projects/07-free-llm-api-router/.env` |
| `WORKERS` | dynamic site (02) | `projects/02-dynamic-site-fastapi/.env` |

## Resource budget on a Pi 5 8 GB

| Workload | RAM | Notes |
|---|---|---|
| Caddy + a static site | ~40 MB | trivial |
| FastAPI app | ~120 MB | trivial |
| Cloudflare Tunnel | ~25 MB | trivial |
| Tailscale | ~30 MB | trivial |
| Ollama + Gemma 3 1B | ~1.5 GB | 18–22 tok/s |
| Ollama + Gemma 3 4B Q4 | ~3.5 GB | 8–11 tok/s |
| Uptime Kuma | ~150 MB | trivial |
| Free-LLM router | ~80 MB | trivial |
| Hybrid LLM app | ~80 MB | trivial |
| Control panel | ~100 MB | trivial |
| **Everything above at once** | **~6.0 GB** | comfortable on 8 GB |

## Conventions

- Internal services bind to `127.0.0.1` only; **Caddy** or **cloudflared** is the single public-facing process.
- Every Compose file sets `restart: unless-stopped`.
- Every README has a **Dependencies**, **Setup**, **Verify** / **Use**, **Resource cost**, and **Production notes** section.
- No project requires a paid domain to *start*; see [`docs/free-domain-dns.md`](docs/free-domain-dns.md) for the options.
- No API keys committed, ever. Every project has a `.env.example`; `.env` is gitignored.

## License

MIT — see [LICENSE](LICENSE).
