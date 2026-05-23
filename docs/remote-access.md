# Remote access — from any device

The whole point of running an AI hub on the Pi is reaching it from **anywhere** — laptop on the train, desktop at work, phone in your pocket, another Pi at a friend's house. Two stacks make that comfortable:

1. **Tailscale (private mesh)** — every device you authorise joins the same virtual network, talks directly to the Pi over WireGuard. No port-forwarding, no public exposure, works behind CGNAT.
2. **A way to talk to the Pi over that mesh** — SSH for CLIs, a browser for the [control panel (project 14)](../projects/14-control-panel/) and [Open WebUI (project 05)](../projects/05-ollama-local-llm/).

Works identically on Linux / macOS / Windows / iOS / Android.

## One-time setup (5 minutes)

1. Install Tailscale on the Pi: [`projects/04-tailscale-private/`](../projects/04-tailscale-private/) (or run `install.sh` and tick the Tailscale box).
2. Install Tailscale on every device you want to reach the Pi from. Sign in with the same account on each.

   | Platform | Where to get it |
   |---|---|
   | macOS | App Store or <https://tailscale.com/download/mac> |
   | Windows | <https://tailscale.com/download/windows> |
   | Linux (laptop / desktop) | `curl -fsSL https://tailscale.com/install.sh \| sh` |
   | iOS | <https://apps.apple.com/app/tailscale/id1470499037> |
   | Android | <https://play.google.com/store/apps/details?id=com.tailscale.ipn> |

3. In the Tailscale admin (<https://login.tailscale.com/admin/dns>) enable **MagicDNS** so the Pi resolves as `pi5.tail-abcd.ts.net` (your tailnet name will differ).

That's it. From now on the Pi is reachable by hostname from every device on the tailnet — your home Wi-Fi, the office, mobile data, a coffee-shop hotspot.

## From a laptop or desktop (the common case)

You already have SSH and a browser. Once Tailscale is connected on both ends:

```bash
# Drop into a shell on the Pi:
ssh you@pi5.tail-abcd.ts.net

# Use any AI CLI as if you were sitting in front of the Pi:
llm "what's the syntax for a python list comprehension?"
aider --model gemini/gemini-2.5-pro
claude

# Open the dashboard:
$BROWSER http://pi5.tail-abcd.ts.net:8000
```

VS Code's **Remote-SSH** extension is excellent for this — open any folder on the Pi and edit it as if it were local.

## From a phone

The same setup, just with a mobile SSH client.

### iOS

| App | Free? | Best for |
|---|---|---|
| **[Termius](https://termius.com)** | ✅ free tier covers basics | The default. Beautiful UI, key sync, snippet pasting. |
| **[Blink Shell](https://blink.sh)** | $20 one-time | Power users; full xterm, `mosh`, `tmux`-aware. |
| **[a-Shell](https://github.com/holzschu/a-shell)** | ✅ free | A real shell *on* your phone (not for SSHing in, but useful) |

### Android

| App | Free? | Best for |
|---|---|---|
| **[Termux](https://termux.dev)** | ✅ free | A real Debian-like terminal. SSH client + much more. |
| **[Termius](https://termius.com)** | ✅ free tier | Cross-platform sync with iOS install |
| **[JuiceSSH](https://juicessh.com)** | ✅ free | Lightweight, dedicated SSH client |

### Quickstart (Termius example)

1. **Keychain** → **+** → **Generate Key**. Type Ed25519.
2. Copy the public key (long string).
3. SSH into the Pi from your laptop once and run:
   ```bash
   mkdir -p ~/.ssh && chmod 700 ~/.ssh
   echo '<paste the Termius public key>' >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```
4. In Termius: **Hosts** → **+** → enter `pi5.tail-abcd.ts.net`, username, pick the key. Save. Tap to connect.

## tmux: never lose a session

Whether you're on a laptop or a phone, networks drop. Install tmux on the Pi and always attach to it — your session survives the drop:

```bash
sudo apt install tmux
ssh pi5.tail-abcd.ts.net "tmux new-session -A -s main"
```

You can now disconnect (switch app on phone, close laptop lid, change Wi-Fi) and the running `claude` / `aider` / model download / whatever picks up exactly where it was when you reconnect.

## The control panel + Open WebUI in a browser

Both work on any device — desktop browser, laptop browser, mobile Safari / Chrome. Once Tailscale is connected:

```
http://pi5.tail-abcd.ts.net:8000   ← control panel (project 14)
http://pi5.tail-abcd.ts.net:3000   ← Open WebUI chat (project 05)
http://pi5.tail-abcd.ts.net:3001   ← Uptime Kuma (project 10)
```

For HTTPS on those hostnames (so browsers stop nagging): `sudo tailscale cert pi5.tail-abcd.ts.net` on the Pi — Tailscale fetches a free Let's Encrypt cert.

On a phone: **Add to Home Screen** turns the control panel into a one-tap launcher.

## Public access — the careful version

If you genuinely need the panel reachable from outside Tailscale (e.g., share read-only status with someone who's not on your tailnet):

- Use [Cloudflare Tunnel (project 03)](../projects/03-cloudflare-tunnel/) for the public URL.
- Add **Cloudflare Access** (free for up to 50 users) in front of it — Cloudflare handles auth (Google, GitHub, email-code) before traffic ever reaches your panel.

Without an extra auth layer in front, **do not** expose the control panel publicly — it has root-equivalent control over your Pi.

## When Tailscale is blocked

Rare, but some corporate / hotel Wi-Fi blocks WireGuard. Fallbacks:

- **Cloudflare Tunnel + Cloudflare Access** — works through any HTTPS-friendly network.
- **mosh** — install `sudo apt install mosh` on the Pi, use Termius/Blink/etc with mosh. Survives terrible cell connections far better than SSH.
