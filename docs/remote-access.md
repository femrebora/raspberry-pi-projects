# Remote access from your phone

The whole point of running an AI hub on the Pi is reaching it from anywhere — phone in your pocket, laptop on the train, work computer. Two stacks make that comfortable:

1. **Tailscale (private mesh)** — your phone joins your tailnet, talks directly to the Pi over WireGuard. No port-forwarding, no public exposure.
2. **An SSH client on the phone** — for running CLIs (Claude, Aider, Gemini, etc.) and browsing the control panel from project 14.

## One-time setup

1. Install Tailscale on the Pi: [`projects/04-tailscale-private/`](../projects/04-tailscale-private/).
2. Install Tailscale on the phone:
   - iOS: <https://apps.apple.com/app/tailscale/id1470499037>
   - Android: <https://play.google.com/store/apps/details?id=com.tailscale.ipn>
   Sign in with the same account you used on the Pi.
3. In the Tailscale admin → **DNS** → enable **MagicDNS** so the Pi is reachable as `pi5.tail-abcd.ts.net` (your tailnet name will differ).
4. Install an SSH client on the phone (see below).

That's it. From now on the Pi is a hostname your phone resolves natively — Wi-Fi, mobile data, hotel networks, anywhere.

## SSH clients

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

1. Generate a key pair: **Keychain** → **+** → **Generate Key**. Set type Ed25519.
2. Copy the public key (long string).
3. SSH into the Pi from your laptop once and run:
   ```bash
   mkdir -p ~/.ssh && chmod 700 ~/.ssh
   echo '<paste the Termius public key>' >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```
4. In Termius: **Hosts** → **+** → enter `pi5.tail-abcd.ts.net`, username, pick the key. Save. Tap to connect.

## Running the CLIs from the phone

Once you're in over SSH, every CLI from [project 13](../projects/13-ai-cli-toolkit/) works as if you were at a keyboard:

```bash
# Ask a question
llm "what's the syntax for a python list comprehension?"

# Pair-program on a repo
cd ~/my-project
aider --model gemini/gemini-2.5-pro

# Full agent
claude
```

Tip: install a tmux session on the Pi (`sudo apt install tmux`) and always attach to it (`tmux attach`). Then you can drop the SSH connection (subway tunnel, switching apps, …) and pick up exactly where you left off when you reconnect.

```bash
ssh pi5.tail-abcd.ts.net "tmux new-session -A -s main"
```

## The control panel from the phone

Project 14's dashboard is a single web page that works fine on mobile Safari / Chrome. Once Tailscale is connected on your phone:

```
http://pi5.tail-abcd.ts.net:8000
```

(Sign in with the basic-auth credentials you set in project 14's `.env`.) Add it to the home screen for a one-tap "PWA-ish" launcher.

For HTTPS on that hostname (so your phone stops nagging): `sudo tailscale cert pi5.tail-abcd.ts.net` on the Pi — Tailscale will fetch a free Let's Encrypt cert.

## Public access — the careful version

If you genuinely need the panel reachable from outside Tailscale (e.g., to share read-only status):

- Use [Cloudflare Tunnel (project 03)](../projects/03-cloudflare-tunnel/) for the public URL.
- Add **Cloudflare Access** (free for up to 50 users) in front of it — Cloudflare handles auth (Google, GitHub, email-code) before traffic ever reaches your panel.

Without an extra auth layer in front, **do not** expose the control panel publicly — it has root-equivalent control over your Pi.

## Offline / no Tailscale

If you're on a network where Tailscale is blocked (some corporate Wi-Fi, very rare): the same control panel via Cloudflare Tunnel + Cloudflare Access is the fallback. Or run a `mosh` server on the Pi (`sudo apt install mosh`) and use Termius/Blink with mosh — survives terrible cell connections better than SSH.
