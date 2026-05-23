# 01 — Static site with Caddy

A static website served by **Caddy** in Docker. Caddy gets you HTTPS automatically: point a domain at the Pi, and Let's Encrypt certificates appear by themselves.

## What you get

- Caddy listening on ports 80 and 443
- A sample site in `site/` you can replace with your own HTML
- Automatic HTTPS via Let's Encrypt (or local self-signed if no public domain)

## Dependencies

| Thing | Why | How to get it |
|---|---|---|
| Docker + Compose | runs Caddy | `shared/scripts/bootstrap.sh` |
| A domain name (optional, but needed for public HTTPS) | Let's Encrypt verifies you own it | DuckDNS (free) or buy a real one — see [`docs/free-domain-dns.md`](../../docs/free-domain-dns.md) |
| Ports 80 + 443 reachable | Let's Encrypt challenge | Either port-forward on your router *or* use [project 03 Cloudflare Tunnel](../03-cloudflare-tunnel/) and skip Caddy's TLS |

## Setup

```bash
cd projects/01-static-site-caddy
cp .env.example .env
# edit .env: set SITE_DOMAIN to your domain (or leave as :80 for HTTP-only local test)
docker compose up -d
```

Verify:

```bash
curl -I http://localhost     # should be 200
docker compose logs caddy    # watch for ACME cert issuance
```

## Replace the sample site

Drop your own `index.html`, CSS, images into `site/`. Caddy reloads automatically; no restart needed.

If you build with a static generator (Hugo, Eleventy, Astro), point its output directory at `site/` or symlink it in.

## Use without a domain (purely local)

Edit `Caddyfile` and replace `{$SITE_DOMAIN}` with `:80`. You'll get HTTP only, but the rest works.

## Resource cost

| Resource | Idle | Under typical load |
|---|---|---|
| RAM | ~30 MB | ~50 MB |
| CPU | <1 % | <5 % |
| Disk | ~50 MB image | + your site |

## Production notes

- **`{$SITE_DOMAIN}`** is read from `.env`; never hard-code your real domain in Caddyfile if you intend to share the repo.
- Caddy stores certificates in the `caddy_data` named volume — back it up so re-deploys don't burn rate limits.
- If you also run project 03 (Cloudflare Tunnel) on the same Pi, **turn off Caddy's HTTPS** (use `:80` in the Caddyfile) and let Cloudflare handle TLS at the edge.

## What breaks first

Hitting Let's Encrypt rate limits (5 duplicate certs / week) if you keep wiping the `caddy_data` volume. Solution: don't wipe it; back it up instead.
