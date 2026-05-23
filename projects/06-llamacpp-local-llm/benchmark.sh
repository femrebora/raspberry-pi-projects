#!/usr/bin/env bash
# Quick perf snapshot for whichever model is installed.

set -euo pipefail

REPO="${REPO:-$HOME/llama.cpp}"
MODEL="${MODEL:-$REPO/models/gemma-3-1b-it-Q4_K_M.gguf}"

[[ -x "$REPO/build/bin/llama-bench" ]] || { echo "Build llama.cpp first (install.sh)." >&2; exit 1; }
[[ -f "$MODEL" ]] || { echo "Model not found: $MODEL" >&2; exit 1; }

"$REPO/build/bin/llama-bench" -m "$MODEL" -t 4 -p 64 -n 128
