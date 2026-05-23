# 03 — Cloudflare Tunnel (free public exposure)

Expose any service on your Pi to the public internet with HTTPS, **without port-forwarding**, **without a public IP**, **without leaking your home IP**. Works behind CGNAT. Free for personal use.

## Why this over Tailscale Funnel?

| | Cloudflare Tunnel | Tailscale Funnel |
|---|---|---|
| Public access (anyone with the URL) | ✅ | ✅ but HTTPS only |
| Custom domain | ✅ free | Only `*.ts.net` |
| Non-HTTP (SSH, game servers, custom TCP/UDP) | ✅ | ❌ |
| Behind CGNAT | ✅ | ✅ |
| Bandwidth cap | None for HTML/JSON (ToS forbids using as CDN for large video) | Soft cap, undocumented |
| Setup difficulty | medium | easy |

Use Cloudflare Tunnel for anything you want **public**. Use Tailscale (project 04) for **private** access. They coexist happily.

## Two modes

### Quick tunnel — zero config

Useful for "show this to a friend for an hour". No domain needed, no Cloudflare account needed.

```bash
docker compose -f docker-compose.quick.yml up
# watch the logs for a https://....trycloudflare.com URL
```

The URL changes every run.

### Persistent named tunnel — recommended

Stable URL like `pi5.yourdomain.com`. Needs:

1. A free Cloudflare account
2. A domain whose DNS is on Cloudflare (move it for free at <https://dash.cloudflare.com>)
3. A tunnel token

#### Get a tunnel token (one-time)

1. <https://one.dash.cloudflare.com> → **Networks** → **Tunnels** → **Create a tunnel** → **Cloudflared** → name it `pi5`.
2. Copy the token shown — it looks like `eyJhIjoi…` (very long).
3. Under **Public hostname**, add:
   - Subdomain: `pi5`
   - Domain: `yourdomain.com`
   - Service: `HTTP` → `caddy:80`  *(or `http://host.docker.internal:80` if your service runs on the Pi host rather than in this Compose network — see below)*

#### Run it

```bash
cp .env.example .env
# paste your token into CF_TUNNEL_TOKEN=
docker compose up -d
docker compose logs -f cloudflared    # should see "Registered tunnel connection"
```

Open `https://pi5.yourdomain.com` — Cloudflare terminates TLS for you.

## How to point at services on the Pi host (not inside Compose)

The Compose network is a separate Docker network. To reach a service running directly on the host (or in a different Compose project), you have two options:

**Option A — join networks.** Add `external: true` networks in both Compose files.

**Option B — use `host` network mode** for `cloudflared`:

```yaml
services:
  cloudflared:
    network_mode: host
    # ... then point Cloudflare public hostnames at http://localhost:<port>
```

`host` mode is simplest on a single Pi.

## Dependencies

| Thing | Why | How to get it |
|---|---|---|
| Docker | runs `cloudflared` | bootstrap script |
| Cloudflare account (free) | issues the token | sign up at <https://dash.cloudflare.com> |
| Domain with Cloudflare DNS | gives you `pi5.yourdomain.com` | any registrar; transfer DNS to Cloudflare (free) |

## Resource cost

| Resource | Idle | Active |
|---|---|---|
| RAM | ~25 MB | ~40 MB |
| CPU | <1 % | scales with traffic |

## Production notes

- Cloudflare's free plan rate-limits at the edge generously for normal sites. The ToS prohibits using it as a free CDN for **video/binary streaming or large file distribution** — read [section 2.8](https://www.cloudflare.com/service-specific-terms-application-services/#content-delivery-network-terms). For a personal site, blog, or API: fine.
- The token is the credential. Anyone with it can serve traffic as your tunnel — keep it out of git, rotate if leaked.
- If `cloudflared` goes down, your public URL stops working *but your services keep running* — they were never publicly exposed. That's the security win.
