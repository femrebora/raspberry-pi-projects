# 04 — Tailscale (private remote access)

Reach your Pi from anywhere — phone, laptop, another Pi — over an encrypted WireGuard mesh. No port-forwarding, no public exposure. Free for **personal use** up to 100 devices.

This is for **private** access only. For *public* URLs use [project 03 Cloudflare Tunnel](../03-cloudflare-tunnel/). They run side-by-side fine.

## What you get

- The Pi becomes another node in your private "tailnet".
- Each device gets a stable hostname like `pi5.tail-abcd.ts.net` (MagicDNS).
- Free **HTTPS certificate** from Let's Encrypt via `tailscale cert`.
- Optional **Tailscale Funnel** to expose ONE HTTPS service publicly under that hostname (limited; HTTPS only, soft bandwidth cap).

## Dependencies

| Thing | Why | How to get it |
|---|---|---|
| Tailscale account (free) | issues device auth keys | sign up at <https://login.tailscale.com> with GitHub/Google/Microsoft |
| One auth key | first-run login | <https://login.tailscale.com/admin/settings/keys> → **Generate auth key** (single-use, reusable, or ephemeral) |

## Two install paths

### Path A — native install (recommended)

Cleaner integration with the host, better for using the Pi as a subnet router or exit node later.

```bash
sudo bash projects/04-tailscale-private/install.sh
sudo tailscale up --ssh
# Follow the URL printed; authenticate in browser.
tailscale status
```

`--ssh` lets you SSH into the Pi using Tailscale's identity layer — you can stop sharing SSH keys and disable LAN sshd later if you want.

### Path B — Docker (isolated, easy to remove)

```bash
cd projects/04-tailscale-private
cp .env.example .env
# paste your tailnet auth key
docker compose up -d
docker compose exec tailscale tailscale status
```

## Get an HTTPS cert (free)

Once the Pi is in your tailnet and MagicDNS is on (admin → DNS):

```bash
sudo tailscale cert pi5.tail-abcd.ts.net
```

You'll get `pi5.tail-abcd.ts.net.crt` and `.key` in the current directory — point Caddy / Nginx at them. Auto-renewal: re-run the command in a daily cron, or use `tailscale serve` which handles it for you.

## Optional: Tailscale Funnel (one public URL)

Make ONE local HTTPS service reachable from the public internet, under your tailnet hostname:

```bash
sudo tailscale funnel 443 on
# expose what's on localhost:8080:
sudo tailscale serve --https=443 / proxy 8080
sudo tailscale funnel 443 on
```

Caveats: HTTPS-only, soft bandwidth limits, not intended for production traffic. For real public hosting use Cloudflare Tunnel (project 03).

## Resource cost

| Resource | Idle | Active |
|---|---|---|
| RAM | ~30 MB | ~50 MB |
| CPU | <1 % | scales with traffic |

## Production notes

- **MagicDNS** must be enabled in the admin console for `*.ts.net` hostnames to resolve.
- Free plan is **personal use** (max 3 users, 100 devices). Beyond that you need a paid plan.
- If you also want to use Tailscale as an **exit node** so the Pi can route your phone's traffic out via your home Wi-Fi: `sudo tailscale up --advertise-exit-node`, then enable the route in the admin console.
