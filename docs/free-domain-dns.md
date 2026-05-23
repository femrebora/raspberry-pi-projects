# Free domains, DNS, and public URLs

A common question: "How do I get a free URL pointing at my Pi?" Several options — pick by use case.

## TL;DR

| You want… | Use |
|---|---|
| An instant public URL, no signup, **for testing** | Cloudflare Quick Tunnel — random `*.trycloudflare.com` |
| A stable free subdomain you control | DuckDNS — `yourname.duckdns.org` |
| A private hostname only your devices reach | Tailscale MagicDNS — `pi5.your-tailnet.ts.net` |
| Your own real domain on Cloudflare Tunnel | Buy a `.com`/`.dev` (~$10/yr) + free Cloudflare DNS |

> **Free TLDs are dead.** Freenom (`.tk`, `.ml`, `.ga`, `.cf`, `.gq`) stopped issuing in 2023 after spam abuse. Anyone offering one in May 2026 is selling you nothing real. A real domain is ~$10/year and the only honest answer.

## Option A — Cloudflare Quick Tunnel (zero-setup public URL)

No account, no key, just one command. Great for showing a friend a project for an hour.

```bash
docker run --rm -it --network=host cloudflare/cloudflared:latest \
  tunnel --url http://localhost:80
```

Cloudflare prints a URL like `https://random-words-1234.trycloudflare.com`. URL changes every run, no persistence.

For a **permanent** tunnel with your own subdomain, see [`../projects/03-cloudflare-tunnel/`](../projects/03-cloudflare-tunnel/).

## Option B — DuckDNS (free dynamic-DNS subdomain)

1. Sign in at <https://www.duckdns.org> with GitHub/Google.
2. Pick a name → you now own `yourname.duckdns.org`.
3. DuckDNS resolves it to whatever IP you tell it. Install the updater on the Pi:

```bash
mkdir -p ~/duckdns && cd ~/duckdns
cat > duck.sh <<'EOF'
echo url="https://www.duckdns.org/update?domains=YOUR_NAME&token=YOUR_TOKEN&ip=" \
  | curl -k -o ~/duckdns/duck.log -K -
EOF
chmod 700 duck.sh
( crontab -l 2>/dev/null; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1" ) | crontab -
```

Replace `YOUR_NAME` and `YOUR_TOKEN`. Your `yourname.duckdns.org` now always points at your Pi's public IP — works for **port-forwarding** setups. Note this requires your ISP to give you a routable IP (not CGNAT). If you're behind CGNAT, use Cloudflare Tunnel instead.

## Option C — Tailscale MagicDNS (private)

Install Tailscale (project 04). Every device gets a free hostname under your tailnet, e.g., `pi5.tail-abcd.ts.net`. Only devices you've added can resolve it. Tailscale will also provision a free **HTTPS cert** for that hostname via Let's Encrypt — no Caddy ACME needed.

```bash
sudo tailscale cert pi5.tail-abcd.ts.net
```

## Option D — Your own real domain

Buy at any registrar — Cloudflare itself sells `.com` near-cost. Then:

1. Move DNS to Cloudflare (free).
2. Use project 03 (Cloudflare Tunnel) for public access — no port-forwarding, free TLS via Cloudflare, no need to expose your home IP.

## CGNAT — am I affected?

Quick test:

```bash
# On the Pi
curl -4 ifconfig.me
# Then compare to what your router says is your WAN IP.
```

If they differ, you're behind CGNAT (very common on mobile broadband, some fibre ISPs in TR/EU). DuckDNS + port-forwarding **won't work**. Cloudflare Tunnel or Tailscale Funnel **will work**, because they make outbound connections from your Pi.
