#!/usr/bin/env bash
# Start llama-server with sane Pi-5 defaults. Exposes OpenAI-compatible HTTP API on :8080.

set -euo pipefail

REPO="${REPO:-$HOME/llama.cpp}"
MODEL="${MODEL:-$REPO/models/gemma-3-1b-it-Q4_K_M.gguf}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"
THREADS="${THREADS:-4}"
CTX="${CTX:-2048}"

exec "$REPO/build/bin/llama-server" \
  --model "$MODEL" \
  --host "$HOST" \
  --port "$PORT" \
  --threads "$THREADS" \
  --ctx-size "$CTX" \
  --mlock
