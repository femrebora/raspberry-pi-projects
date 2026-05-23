# Voice add-on — Whisper.cpp + Piper + Ollama

Build a local voice loop: **microphone → transcribe → LLM → speak → speaker**. Everything runs on the Pi. No cloud.

## Components

| Piece | Role | Source |
|---|---|---|
| **arecord** | capture mic | `alsa-utils` (pre-installed on Pi OS) |
| **whisper.cpp** | speech-to-text | <https://github.com/ggerganov/whisper.cpp> |
| **Ollama** (project 05) | the LLM | already running |
| **Piper** | text-to-speech | <https://github.com/rhasspy/piper> |
| **aplay** | play audio | `alsa-utils` |

## One-time setup

```bash
sudo apt install -y build-essential cmake git alsa-utils

# Whisper.cpp + a tiny English model (~75 MB)
git clone https://github.com/ggerganov/whisper.cpp ~/whisper.cpp
cd ~/whisper.cpp && cmake -B build && cmake --build build -j4
bash models/download-ggml-model.sh tiny.en

# Piper TTS binary + a voice model (~30 MB)
mkdir -p ~/piper && cd ~/piper
curl -L https://github.com/rhasspy/piper/releases/latest/download/piper_arm64.tar.gz | tar xz
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json
```

Verify Ollama is up: `curl localhost:11434/api/tags`.

## Run the loop

```bash
bash voice-loop.sh
```

Speak when prompted, wait, listen. Hit `Ctrl-C` to quit.

## Tuning

- Replace `tiny.en` with `base.en` for better accuracy (`models/download-ggml-model.sh base.en`) — about 3× slower transcription.
- Swap the Ollama model in `voice-loop.sh` (the `MODEL=` line) for `gemma3:1b` if `qwen2.5:0.5b` feels too dumb.
- For a wake-word ("hey pi"), look at [openWakeWord](https://github.com/dscripka/openWakeWord) — out of scope here.

## Why not Home Assistant Voice?

It's better-engineered. But this 30-line shell script is a great starting point that teaches you what each piece does. Graduate to HA Voice or Rhasspy when you want polish.
