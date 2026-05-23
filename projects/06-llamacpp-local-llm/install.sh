#!/usr/bin/env bash
# Build llama.cpp on Pi 5 (ARM64) with NEON. Downloads one starter model.
# Idempotent.

set -euo pipefail

REPO="${REPO:-$HOME/llama.cpp}"
MODEL_URL="${MODEL_URL:-https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf}"
MODEL_PATH="${MODEL_PATH:-$REPO/models/gemma-3-1b-it-Q4_K_M.gguf}"

if [[ ! -d "$REPO" ]]; then
  git clone --depth 1 https://github.com/ggml-org/llama.cpp.git "$REPO"
fi

cd "$REPO"
git pull --ff-only || true

# Build with curl support (for llama-server hot model loads) if libcurl present.
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_NATIVE=ON \
  -DLLAMA_CURL="$(pkg-config --exists libcurl && echo ON || echo OFF)"
cmake --build build -j"$(nproc)" --target llama-cli llama-server llama-bench

mkdir -p "$REPO/models"
if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Downloading starter model (~700 MB)…"
  curl -L --fail --retry 3 "$MODEL_URL" -o "$MODEL_PATH"
fi

echo
echo "Done."
echo "  Binary: $REPO/build/bin/llama-cli"
echo "  Server: $REPO/build/bin/llama-server"
echo "  Model:  $MODEL_PATH"
echo
echo "Try:  $REPO/build/bin/llama-cli -m $MODEL_PATH -p 'Hello' -n 50 -t 4"
