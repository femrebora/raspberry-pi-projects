# 13 — AI CLI toolkit (Claude, Gemini, Codex, Aider, llm, sgpt)

Turn your Pi into a personal AI hub you can reach from anywhere. SSH in from your **laptop, desktop, or phone**, run any of these CLIs, get answers from any frontier model. All keys live on the Pi; the remote device is just a terminal.

## What gets installed

| Tool | Backend | What it's good at | Auth |
|---|---|---|---|
| **Claude Code** | Anthropic Claude 4.x | Agentic coding, multi-step tasks, file edits | OAuth token or `ANTHROPIC_API_KEY` |
| **Gemini CLI** | Google Gemini 2.5 | Free 60 RPM / 1 k RPD with personal Google account | OAuth (browser) or `GEMINI_API_KEY` |
| **Codex CLI** | OpenAI GPT-4.x / Codex | OpenAI's official agentic CLI | `OPENAI_API_KEY` |
| **Aider** | **anything** — Anthropic, OpenAI, Gemini, DeepSeek, Groq, Ollama | Best AI pair-programmer; provider-agnostic | env vars per provider |
| **`llm`** (Simon Willison) | **anything** via plugins | Quick one-shot queries from the shell, scriptable | env vars |
| **`sgpt`** (shell-gpt) | OpenAI-compatible (incl. our router) | Tiny ChatGPT-style shell prompt | `OPENAI_API_KEY` (or point at router) |

> All of these are command-line tools. From a laptop / desktop, `ssh` in (or use VS Code's Remote-SSH). From a phone, install an SSH client and connect over Tailscale. Full guide: [`docs/remote-access.md`](../../docs/remote-access.md).

## Setup

```bash
bash projects/13-ai-cli-toolkit/install.sh
```

The script:

1. Installs Node 20+ (via NodeSource) and Python 3 — needed for the npm- and pip-based CLIs.
2. Sets up `~/.npm-global` so global npm installs **don't require sudo**.
3. Installs every CLI in the table above.
4. Drops a `~/.aiclirc` template you copy to `~/.ai_keys` and source from your shell — central place for every key.

After it finishes:

```bash
cp ~/.aiclirc ~/.ai_keys
$EDITOR ~/.ai_keys   # paste the keys you want (any missing one = that CLI just won't work)
echo 'source ~/.ai_keys' >> ~/.bashrc
exec $SHELL
```

## Sign-up links (all have free options)

| Provider | Free? | URL |
|---|---|---|
| Anthropic | API: pay-as-you-go (~$3/$15 per M tokens for Sonnet); Claude Pro $20/mo includes CLI access | <https://console.anthropic.com/settings/keys> |
| OpenAI | API: pay-as-you-go from $0.15/M tokens (4o-mini); $5 free trial | <https://platform.openai.com/api-keys> |
| Google Gemini | **Yes** — 60 RPM, 1 000 RPD free with personal Google account | <https://aistudio.google.com/apikey> |
| DeepSeek | **Effectively free**: $0.07/M cached input, $1.10/M output (cheapest frontier) | <https://platform.deepseek.com> |
| Groq | **Yes** — 1 000 RPD, 315 tok/s, free Llama/Gemma | <https://console.groq.com/keys> |
| OpenRouter | **Yes** — many `:free` models, no card | <https://openrouter.ai/keys> |

> Claude Code and OpenAI Codex CLI require **paid API access** for full use. If you want pure-free, the Aider + (Gemini or Groq or DeepSeek) combination gives you a top-tier coding assistant at zero cost.

## Use it

```bash
# One-shot questions
llm "summarise the diff between Pi 5 and Pi 4 in 3 bullets" -m gemini-2.5-flash
sgpt "command to count files in a directory by extension"

# Agentic pair-programming on a repo
cd ~/my-project
aider                                  # uses your default model (set ALIAS env)
aider --model gemini/gemini-2.5-pro    # pin a model
aider --model ollama/gemma3:1b         # use the LOCAL Ollama from project 05 — fully offline + free

# Claude Code, full agent
cd ~/my-project
claude

# Gemini CLI
gemini
```

## Hooking CLIs into the LOCAL router (project 07)

Most of these CLIs honour `OPENAI_API_KEY` + `OPENAI_BASE_URL`. Point them at the router and you get free-tier failover automatically:

```bash
export OPENAI_API_KEY="not-needed"
export OPENAI_BASE_URL="http://localhost:8088/v1"

sgpt "hello"            # served by Groq → Cerebras → … via the router
aider --openai-api-base http://localhost:8088/v1 --model gpt-3.5-turbo
```

## Hooking CLIs into LOCAL Ollama (project 05)

Most CLIs support Ollama natively. For ones that don't, Ollama exposes an OpenAI-compatible endpoint at `http://localhost:11434/v1`:

```bash
export OPENAI_BASE_URL="http://localhost:11434/v1"
aider --model gemma3:1b   # answered locally, no network at all
```

## Heads-up on Gemini CLI changes

Google has announced that **unpaid Gemini CLI users will migrate to "Antigravity CLI" on 2026-06-18**. The install script tracks the stable channel; if your `gemini` command stops working after that date, run `npm install -g @google/antigravity-cli` (or whatever Google publishes — check their docs).

## Resource cost

The CLIs themselves are tiny (each <100 MB on disk, <50 MB RAM idle). Real cost happens at the provider, not on your Pi.

## Production notes

- Keep `~/.ai_keys` mode `600` and out of git. (`install.sh` handles the mode.)
- If multiple users SSH into the Pi, each one has their own `~/.ai_keys`.
- These are interactive tools. For automation (scripts, cron, web hooks), use the project 07 router instead.
