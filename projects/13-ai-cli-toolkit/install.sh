#!/usr/bin/env bash
# Install a suite of AI CLIs on a Pi 5 (or any aarch64 Linux box).
# Idempotent: re-run any time to update.
#
# Installs: Node 20, npm-without-sudo, Claude Code, Gemini CLI, OpenAI Codex CLI,
# Aider, llm (+ plugins), shell-gpt.
#
# Usage: bash install.sh

set -euo pipefail

log() { printf '\033[1;34m[ai-cli]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ai-cli]\033[0m %s\n' "$*" >&2; }

[[ $EUID -ne 0 ]] || { echo "Run as your regular user, not root." >&2; exit 1; }

# --- 1. system packages -----------------------------------------------------
if ! command -v node >/dev/null || [[ "$(node -v | sed 's/v\([0-9]*\).*/\1/')" -lt 20 ]]; then
  log "Installing Node.js 20.x from NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

sudo apt-get install -y python3 python3-venv python3-pip pipx
pipx ensurepath >/dev/null 2>&1 || true

# --- 2. npm-global without sudo --------------------------------------------
NPM_PREFIX="$HOME/.npm-global"
mkdir -p "$NPM_PREFIX"
npm config set prefix "$NPM_PREFIX"
if ! grep -q "$NPM_PREFIX/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$NPM_PREFIX/bin:\$PATH\"" >> "$HOME/.bashrc"
fi
export PATH="$NPM_PREFIX/bin:$PATH"

# --- 3. npm-based CLIs ------------------------------------------------------
log "Installing Claude Code (Anthropic)"
npm install -g @anthropic-ai/claude-code || warn "Claude Code install failed — try again later"

log "Installing Gemini CLI (Google)"
npm install -g @google/gemini-cli || warn "Gemini CLI install failed — try again later"

log "Installing OpenAI Codex CLI"
npm install -g @openai/codex || warn "Codex CLI install failed — try again later"

# --- 4. pip-based CLIs (via pipx for isolation) -----------------------------
log "Installing Aider (pipx)"
pipx install --force aider-chat || warn "aider install failed"

log "Installing llm (Simon Willison, pipx)"
pipx install --force llm || true
# Plugins — installed *into* the pipx-managed llm venv.
for plugin in llm-claude-3 llm-gemini llm-deepseek llm-groq llm-ollama; do
  pipx inject llm "$plugin" || warn "llm plugin $plugin failed (skipping)"
done

log "Installing shell-gpt (sgpt, pipx)"
pipx install --force shell-gpt || warn "shell-gpt install failed"

# --- 5. drop the env-var template ------------------------------------------
TEMPLATE="$HOME/.aiclirc"
log "Writing key template to $TEMPLATE"
cat > "$TEMPLATE" <<'EOF'
# Source this file (or copy to ~/.ai_keys and source that) to populate every
# AI CLI's expected env vars. Any var you leave empty just means that CLI
# can't use that provider.
#
# Keep this file mode 0600.

# --- Anthropic / Claude Code -----------------------------------------------
# Either ANTHROPIC_API_KEY *or* CLAUDE_CODE_OAUTH_TOKEN (run `claude setup-token`
# on your laptop to mint an OAuth token, then paste it here).
export ANTHROPIC_API_KEY=""
export CLAUDE_CODE_OAUTH_TOKEN=""

# --- OpenAI / Codex CLI / sgpt ---------------------------------------------
export OPENAI_API_KEY=""
# Point OPENAI_BASE_URL at http://localhost:8088/v1 (project 07 router) or
# http://localhost:11434/v1 (project 05 Ollama) to route OpenAI clients locally.
# export OPENAI_BASE_URL="http://localhost:8088/v1"

# --- Google Gemini ---------------------------------------------------------
export GEMINI_API_KEY=""
export GOOGLE_API_KEY="$GEMINI_API_KEY"   # llm-gemini & some others use this name

# --- DeepSeek --------------------------------------------------------------
export DEEPSEEK_API_KEY=""

# --- Groq ------------------------------------------------------------------
export GROQ_API_KEY=""

# --- OpenRouter ------------------------------------------------------------
export OPENROUTER_API_KEY=""
EOF
chmod 600 "$TEMPLATE"

log "Done."
log ""
log "Next steps:"
log "  cp ~/.aiclirc ~/.ai_keys"
log "  \$EDITOR ~/.ai_keys                 # paste the keys you want"
log "  echo 'source ~/.ai_keys' >> ~/.bashrc"
log "  exec \$SHELL"
log ""
log "Try:"
log "  llm models                          # list every model you can reach"
log "  llm 'hi' -m gemini-2.5-flash"
log "  aider --model deepseek              # in any git repo"
log "  claude                              # in any git repo"
