#!/usr/bin/env bash
# raspberry-pi-projects — one-shot interactive installer.
#
#   curl -fsSL https://raw.githubusercontent.com/femrebora/raspberry-pi-projects/main/install.sh | bash
#   OR (recommended — review first):
#       git clone https://github.com/femrebora/raspberry-pi-projects.git
#       cd raspberry-pi-projects && bash install.sh
#
# What it does:
#   1. Confirms you're on Debian / Pi OS.
#   2. Installs Docker + Compose + swap + base packages (via shared/scripts/bootstrap.sh).
#   3. Optionally applies the security baseline (ufw + fail2ban + auto-updates).
#   4. Lets you pick which projects to deploy from a TUI checklist.
#   5. Prompts for any API keys / tokens each chosen project needs.
#   6. Writes the .env files, brings up the Compose stacks, prints final URLs.
#
# Re-run any time to add more projects or update keys. Idempotent.

set -euo pipefail

# --- pretty output ---------------------------------------------------------
BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
log()  { printf '%s[install]%s %s\n' "$BLUE$BOLD" "$RESET" "$*"; }
ok()   { printf '%s[install]%s %s\n' "$GREEN$BOLD" "$RESET" "$*"; }
warn() { printf '%s[install]%s %s\n' "$YELLOW$BOLD" "$RESET" "$*" >&2; }
die()  { printf '%s[install]%s %s\n' "$RED$BOLD"    "$RESET" "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# --- sanity checks ---------------------------------------------------------
[[ $EUID -ne 0 ]] || die "Run as your regular user (the script will sudo when needed)."
command -v sudo >/dev/null || die "sudo is required."
[[ -d projects ]] || die "Run this from the repo root (where projects/ lives)."

if [[ ! -f /etc/debian_version ]]; then
  warn "This installer targets Debian / Raspberry Pi OS. Other distros may need tweaks."
fi

# Install whiptail if missing — it's preinstalled on Pi OS but not on minimal Debian.
if ! command -v whiptail >/dev/null; then
  log "Installing whiptail (TUI prompts)…"
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends whiptail
fi

# --- welcome ---------------------------------------------------------------
whiptail --title "raspberry-pi-projects" --msgbox \
"Welcome.

This installer will set up your Pi 5 with as many or as few of the projects in this repo as you want.

Steps:
 1. Base bootstrap (Docker + swap + kernel tweaks)
 2. (Optional) Security baseline (ufw + fail2ban + auto-updates)
 3. Project picker — choose what to deploy
 4. Per-project key prompts
 5. Bring everything up

You can re-run this any time to add more projects or change keys.

Hit OK to begin." 22 70

# --- 1. base bootstrap -----------------------------------------------------
if whiptail --title "Base bootstrap" --yesno \
"Run shared/scripts/bootstrap.sh now?

It installs Docker + Compose, sets up a 1 GB swapfile, and lowers swappiness.

Safe to skip if you've already run it." 12 70; then
  log "Running shared/scripts/bootstrap.sh…"
  bash shared/scripts/bootstrap.sh
  ok "Base bootstrap done."
  if ! groups | grep -q docker; then
    warn "You were added to the 'docker' group. Log out and back in once after this installer finishes for it to take effect."
  fi
fi

# --- 2. security baseline --------------------------------------------------
if whiptail --title "Security baseline" --yesno \
"Apply the security baseline?

Installs ufw + fail2ban + unattended-upgrades, hardens sshd (KEY-ONLY login).

WARNING: this DISABLES SSH password login. Make sure your SSH key works first." 14 72; then
  log "Running security baseline…"
  sudo bash projects/11-security-baseline/bootstrap.sh
  ok "Security baseline applied."
fi

# --- 3. project picker -----------------------------------------------------
CHOICES=$(whiptail --title "Pick projects to deploy" --checklist \
"Space to toggle, Enter to confirm.\n\n(Idempotent — already-running stacks won't break if re-selected.)" 24 78 14 \
  "01-static-site-caddy"      "Static site + Caddy (auto-HTTPS)"          OFF \
  "02-dynamic-site-fastapi"   "FastAPI dynamic site + Caddy"               OFF \
  "03-cloudflare-tunnel"      "Free public exposure (Cloudflare Tunnel)"   OFF \
  "04-tailscale-private"      "Private mesh (Tailscale, native install)"   OFF \
  "05-ollama-local-llm"       "Ollama + Open WebUI (local LLM)"            ON  \
  "07-free-llm-api-router"    "Free-LLM API router (Groq/Gemini/…)"        ON  \
  "08-hybrid-llm-fallback"    "Hybrid local+cloud LLM app"                 OFF \
  "10-monitoring-uptime"      "Uptime Kuma monitoring"                     OFF \
  "11-watchtower"             "Watchtower (Docker image auto-update)"      OFF \
  "12-backups"                "restic encrypted backups (systemd timer)"   OFF \
  "13-ai-cli-toolkit"         "Claude/Gemini/Codex/Aider/llm CLIs"         ON  \
  "14-control-panel"          "Web dashboard for all the above"            ON  \
  3>&1 1>&2 2>&3) || die "Cancelled."

# Strip whiptail's quotes.
CHOICES=$(echo "$CHOICES" | tr -d '"')
log "You picked: $CHOICES"

# --- helper: write a .env file from a key=value list ----------------------
write_env() {
  local dir="$1"; shift
  local out="$dir/.env"
  : > "$out"
  echo "# Written by install.sh — keep this file out of git." >> "$out"
  for kv in "$@"; do
    echo "$kv" >> "$out"
  done
  chmod 600 "$out"
  log "Wrote $out"
}

# --- helper: bring a compose stack up -------------------------------------
compose_up() {
  local dir="$1"
  local f="${2:-docker-compose.yml}"
  log "docker compose -f $dir/$f up -d --remove-orphans"
  ( cd "$dir" && docker compose -f "$f" up -d --remove-orphans )
}

# --- helper: read a possibly-secret value via whiptail --------------------
ask() {                 # ask "Title" "Prompt" [default]
  whiptail --title "$1" --inputbox "$2" 10 70 "${3:-}" 3>&1 1>&2 2>&3
}
asksecret() {           # asksecret "Title" "Prompt"
  whiptail --title "$1" --passwordbox "$2" 10 70 3>&1 1>&2 2>&3
}

# Pre-collect a few keys that are shared across multiple projects so we ask once.
GROQ_API_KEY=""; GEMINI_API_KEY=""; CEREBRAS_API_KEY=""; OPENROUTER_API_KEY=""; HF_API_KEY=""
collect_llm_keys_if_needed() {
  if echo " $CHOICES " | grep -qE " 07-free-llm-api-router | 08-hybrid-llm-fallback "; then
    whiptail --title "Free-LLM API keys" --msgbox \
"Next: paste any free-LLM API keys you have.

LEAVE BLANK to skip a provider — the router just won't use it.

Sign-ups (all free, no credit card unless noted):
  Groq        https://console.groq.com/keys
  Gemini      https://aistudio.google.com/apikey
  Cerebras    https://cloud.cerebras.ai
  OpenRouter  https://openrouter.ai/keys
  HuggingFace https://huggingface.co/settings/tokens" 22 78
    GROQ_API_KEY=$(asksecret      "GROQ_API_KEY"      "Groq key (blank to skip):"      || true)
    GEMINI_API_KEY=$(asksecret    "GEMINI_API_KEY"    "Gemini key (blank to skip):"    || true)
    CEREBRAS_API_KEY=$(asksecret  "CEREBRAS_API_KEY"  "Cerebras key (blank to skip):"  || true)
    OPENROUTER_API_KEY=$(asksecret "OPENROUTER_API_KEY" "OpenRouter key (blank to skip):" || true)
    HF_API_KEY=$(asksecret        "HF_API_KEY"        "Hugging Face key (blank to skip):" || true)
  fi
}
collect_llm_keys_if_needed

# --- per-project handlers -------------------------------------------------
URLS=()

for project in $CHOICES; do
  case "$project" in

    01-static-site-caddy)
      DOMAIN=$(ask "Domain" "Domain for Caddy (':80' = local HTTP only, or e.g. pi5.example.com):" ":80")
      write_env "projects/01-static-site-caddy" "SITE_DOMAIN=$DOMAIN"
      compose_up "projects/01-static-site-caddy"
      URLS+=("Static site:           http://<pi-ip>/  (HTTPS once $DOMAIN resolves to the Pi)")
      ;;

    02-dynamic-site-fastapi)
      DOMAIN=$(ask "Domain" "Domain for the FastAPI site (':80' for local):" ":80")
      write_env "projects/02-dynamic-site-fastapi" "SITE_DOMAIN=$DOMAIN" "WORKERS=2"
      compose_up "projects/02-dynamic-site-fastapi"
      URLS+=("Dynamic site:          http://<pi-ip>/  (API at /api/health)")
      ;;

    03-cloudflare-tunnel)
      TOKEN=$(asksecret "Cloudflare Tunnel token" \
"Get one at https://one.dash.cloudflare.com → Networks → Tunnels → Create a tunnel → Cloudflared.

Paste the full token (eyJhIjoi…):")
      [[ -n "$TOKEN" ]] || { warn "Empty token — skipping Cloudflare Tunnel."; continue; }
      write_env "projects/03-cloudflare-tunnel" "CF_TUNNEL_TOKEN=$TOKEN"
      compose_up "projects/03-cloudflare-tunnel"
      URLS+=("Cloudflare Tunnel:     check Cloudflare Zero Trust dashboard for the public hostname")
      ;;

    04-tailscale-private)
      whiptail --title "Tailscale" --msgbox \
"Native install (cleaner than Docker for Tailscale).

After install.sh finishes, run:
    sudo tailscale up --ssh

…and follow the URL printed to authenticate. Your Pi will then be reachable as <hostname>.<tailnet>.ts.net from any device on your tailnet." 16 78
      sudo bash projects/04-tailscale-private/install.sh
      URLS+=("Tailscale:             run 'sudo tailscale up --ssh' to finish — then hostname.tailnet.ts.net")
      ;;

    05-ollama-local-llm)
      compose_up "projects/05-ollama-local-llm"
      log "Pulling starter model gemma3:1b (~700 MB, one-time)…"
      ( docker exec ollama ollama pull gemma3:1b ) || warn "Couldn't pull gemma3:1b yet — Ollama may still be starting. Try again with: docker exec ollama ollama pull gemma3:1b"
      URLS+=("Open WebUI:            http://<pi-ip>:3000   (sign up — first user is admin)")
      URLS+=("Ollama API:            http://<pi-ip>:11434  (OpenAI-compatible at /v1)")
      ;;

    07-free-llm-api-router)
      write_env "projects/07-free-llm-api-router" \
        "GROQ_API_KEY=$GROQ_API_KEY" \
        "GEMINI_API_KEY=$GEMINI_API_KEY" \
        "CEREBRAS_API_KEY=$CEREBRAS_API_KEY" \
        "OPENROUTER_API_KEY=$OPENROUTER_API_KEY" \
        "HF_API_KEY=$HF_API_KEY" \
        "PROVIDER_ORDER=groq,cerebras,gemini,openrouter,huggingface" \
        "REQUEST_TIMEOUT=30"
      compose_up "projects/07-free-llm-api-router"
      URLS+=("Free-LLM router:       http://<pi-ip>:8088   (OpenAI-compatible /v1/chat/completions)")
      ;;

    08-hybrid-llm-fallback)
      write_env "projects/08-hybrid-llm-fallback" \
        "OLLAMA_URL=http://host.docker.internal:11434" \
        "OLLAMA_MODEL=gemma3:1b" \
        "ROUTER_URL=http://host.docker.internal:8088" \
        "OLLAMA_TIMEOUT=30" \
        "ROUTER_TIMEOUT=30"
      compose_up "projects/08-hybrid-llm-fallback"
      URLS+=("Hybrid LLM app:        http://<pi-ip>:8090/chat")
      ;;

    10-monitoring-uptime)
      compose_up "projects/10-monitoring-uptime"
      URLS+=("Uptime Kuma:           http://<pi-ip>:3001   (sign up — first user is admin)")
      ;;

    11-watchtower)
      compose_up "projects/11-security-baseline" "docker-compose.watchtower.yml"
      URLS+=("Watchtower:            running silently; updates images daily")
      ;;

    12-backups)
      REPO=$(ask "restic repository" \
"Where to store backups. Examples:
  /mnt/backup-drive/restic
  b2:your-bucket-name:pi5
  s3:s3.amazonaws.com/your-bucket/pi5" \
        "/mnt/backup-drive/restic")
      PASS=$(asksecret "restic password" "Encryption password (LOSE THIS = LOSE BACKUPS, store off-Pi):")
      [[ -n "$PASS" ]] || { warn "Empty password — skipping backups."; continue; }
      write_env "projects/12-backups" "RESTIC_REPOSITORY=$REPO" "RESTIC_PASSWORD=$PASS"
      sudo apt-get install -y --no-install-recommends restic
      sudo install -m 0755 projects/12-backups/restic-backup.sh /usr/local/sbin/
      sudo install -m 0644 projects/12-backups/systemd/restic-backup.service /etc/systemd/system/
      sudo install -m 0644 projects/12-backups/systemd/restic-backup.timer   /etc/systemd/system/
      sudo install -m 0600 projects/12-backups/.env /etc/default/restic-backup
      sudo systemctl daemon-reload
      sudo --preserve-env=RESTIC_REPOSITORY,RESTIC_PASSWORD \
        env RESTIC_REPOSITORY="$REPO" RESTIC_PASSWORD="$PASS" \
        restic init 2>/dev/null || true   # ignore "already initialised"
      sudo systemctl enable --now restic-backup.timer
      URLS+=("restic backups:        daily at 03:30 (systemctl list-timers | grep restic)")
      ;;

    13-ai-cli-toolkit)
      bash projects/13-ai-cli-toolkit/install.sh
      URLS+=("AI CLI toolkit:        ~/.aiclirc template — copy to ~/.ai_keys + edit, then 'source ~/.ai_keys'")
      ;;

    14-control-panel)
      PANEL_USER=$(ask "Panel username" "Login username for the control panel:" "admin")
      PANEL_PASSWORD=$(asksecret "Panel password" "Choose a strong password for the control panel:")
      [[ -n "$PANEL_PASSWORD" ]] || die "Empty panel password — refusing."
      write_env "projects/14-control-panel" \
        "PANEL_USER=$PANEL_USER" \
        "PANEL_PASSWORD=$PANEL_PASSWORD" \
        "OLLAMA_URL=http://host.docker.internal:11434" \
        "ROUTER_URL=http://host.docker.internal:8088"
      compose_up "projects/14-control-panel"
      URLS+=("Control panel:         http://<pi-ip>:8000   (login: $PANEL_USER)")
      ;;

    *)
      warn "Unknown project: $project — skipped"
      ;;
  esac
done

# --- 4. final summary -----------------------------------------------------
SUMMARY="Done.\n\n"
if (( ${#URLS[@]} == 0 )); then
  SUMMARY+="No projects selected.\n"
else
  SUMMARY+="Your Pi is now serving:\n\n"
  for u in "${URLS[@]}"; do
    SUMMARY+="  • $u\n"
  done
fi
SUMMARY+="\nReplace <pi-ip> with your Pi's IP / Tailscale name.\n"
SUMMARY+="\nRe-run this installer any time to add projects, change keys, or repair stacks."

whiptail --title "All done" --msgbox "$SUMMARY" 24 78
printf '\n%s\n' "$SUMMARY"
