# 02 — Dynamic site with FastAPI + Caddy

A Python web app (**FastAPI**) running behind a **Caddy** reverse proxy. Use this skeleton for any dynamic site, JSON API, or LLM front-end.

## Architecture

```
internet ── 443 ──► caddy ── 127.0.0.1:8000 ──► fastapi
                     │
                     └── handles TLS, gzip, security headers
```

Caddy is the only thing exposed publicly. FastAPI binds to localhost inside the Compose network — never reachable directly.

## Dependencies

| Thing | Why | How to get it |
|---|---|---|
| Docker + Compose | runs both services | `shared/scripts/bootstrap.sh` |
| (Optional) domain | for HTTPS | see [`docs/free-domain-dns.md`](../../docs/free-domain-dns.md) |

## Setup

```bash
cd projects/02-dynamic-site-fastapi
cp .env.example .env
# edit .env: SITE_DOMAIN as in project 01
docker compose up -d --build
```

Verify:

```bash
curl http://localhost/api/health
# {"status":"ok","host":"<container-id>"}
curl http://localhost/
# HTML hello page
```

## How to extend

The app lives in `app/main.py`. Add routes, swap in your own templates, mount static assets — it's standard FastAPI. Compose rebuilds on `docker compose up --build`.

For a database, add a Postgres service to `docker-compose.yml` and bind it to `127.0.0.1` only:

```yaml
db:
  image: postgres:16-alpine
  restart: unless-stopped
  environment:
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  volumes:
    - db_data:/var/lib/postgresql/data
  # no `ports:` block — only the app container can reach it
```

## Resource cost

| Resource | Idle | Under load |
|---|---|---|
| RAM | ~120 MB total | ~250 MB |
| CPU | <1 % | scales with traffic |
| Disk | ~150 MB images | + your DB |

## Production notes

- The Dockerfile installs deps with `pip install --no-cache-dir`; for faster rebuilds during development, mount `./app` as a volume and run `uvicorn --reload`.
- Always set a non-trivial `WORKERS` in `.env` for sustained traffic — but on a Pi 5, **2** is usually the sweet spot. More workers = more RAM, not always more throughput.
