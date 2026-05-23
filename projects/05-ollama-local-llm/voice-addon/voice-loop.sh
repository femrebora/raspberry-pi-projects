#!/usr/bin/env bash
# Tiny local voice assistant: mic → whisper.cpp → ollama → piper → speaker.
# Edit MODEL / VOICE / WHISPER_BIN to taste.

set -euo pipefail

WHISPER_DIR="${WHISPER_DIR:-$HOME/whisper.cpp}"
WHISPER_BIN="$WHISPER_DIR/build/bin/whisper-cli"
WHISPER_MODEL="$WHISPER_DIR/models/ggml-tiny.en.bin"

PIPER_DIR="${PIPER_DIR:-$HOME/piper}"
PIPER_BIN="$PIPER_DIR/piper/piper"
PIPER_VOICE="$PIPER_DIR/en_US-lessac-medium.onnx"

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${MODEL:-gemma3:1b}"

for f in "$WHISPER_BIN" "$WHISPER_MODEL" "$PIPER_BIN" "$PIPER_VOICE"; do
  [[ -e "$f" ]] || { echo "Missing: $f — see README.md" >&2; exit 1; }
done
command -v arecord >/dev/null || { echo "arecord not found (sudo apt install alsa-utils)" >&2; exit 1; }
command -v aplay   >/dev/null || { echo "aplay not found"   >&2; exit 1; }
command -v jq      >/dev/null || { echo "jq not found (sudo apt install jq)" >&2; exit 1; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

while true; do
  echo
  read -rp "[Enter] to record 5s of audio, q to quit: " key
  [[ "$key" == "q" ]] && break

  echo "Recording…"
  arecord -q -D default -f S16_LE -c1 -r16000 -d5 "$TMP/in.wav"

  echo "Transcribing…"
  TEXT=$("$WHISPER_BIN" -m "$WHISPER_MODEL" -f "$TMP/in.wav" -nt -otxt -of "$TMP/in" 2>/dev/null \
          && cat "$TMP/in.txt" | tr '\n' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  echo "You said: $TEXT"
  [[ -z "$TEXT" ]] && { echo "Empty transcription, skipping."; continue; }

  echo "Asking $MODEL…"
  REPLY=$(curl -s "$OLLAMA_URL/api/generate" \
    -d "$(jq -nc --arg m "$MODEL" --arg p "$TEXT" '{model:$m, prompt:$p, stream:false}')" \
    | jq -r .response)
  echo "Reply: $REPLY"

  echo "Speaking…"
  echo "$REPLY" | "$PIPER_BIN" --model "$PIPER_VOICE" --output_file "$TMP/out.wav"
  aplay -q "$TMP/out.wav"
done

echo "Bye."
