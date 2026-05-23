# 05 — Local LLM with Ollama + Open WebUI

Run an actual open-source LLM **on the Pi**, with a ChatGPT-like browser UI. Free, private, offline-capable. No API keys needed.

## What you get

- **Ollama** server (port 11434) — OpenAI-compatible API at `/v1/chat/completions`
- **Open WebUI** (port 3000) — clean chat interface, model picker, multi-user
- A few small models pre-queued for the Pi 5 8 GB

## Dependencies

| Thing | Why | How to get it |
|---|---|---|
| Docker + Compose | runs both | bootstrap script |
| Pi 5 with **active cooler** | sustained inference = 100% CPU | see [`docs/hardware-setup.md`](../../docs/hardware-setup.md) |
| ~5 GB free disk per medium model | model weights | NVMe / USB SSD recommended |

## Setup

```bash
cd projects/05-ollama-local-llm
docker compose up -d
# Pull the recommended starter models (one-time, downloads ~3 GB total):
docker exec -it ollama ollama pull gemma3:1b
docker exec -it ollama ollama pull phi3:mini
```

Open `http://<pi-ip>:3000` and create your first Open WebUI user — the first sign-up becomes admin.

## Test from the command line

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3:1b",
  "prompt": "Say hi in 5 words.",
  "stream": false
}'
```

## Picking a model

See [`benchmarks.md`](benchmarks.md) for measured tokens/sec on a Pi 5 8 GB, and [`alt-models.md`](alt-models.md) for the best alternatives per task (coding, reasoning, vision, multilingual, embeddings). Short version:

| Need | Use | Speed |
|---|---|---|
| Snappy chat | `gemma3:1b` | 18–22 tok/s |
| Best quality / size | `gemma3:4b` (Q4_K_M) | 8–11 tok/s |
| Coding help | `qwen2.5:1.5b` | 12–15 tok/s |
| Smallest possible | `tinyllama` (1.1B) | 25+ tok/s |
| Speech | see [`voice-addon/`](voice-addon/) |

## Voice add-on (optional)

[`voice-addon/`](voice-addon/) wires Ollama into Whisper.cpp (speech-to-text) and Piper (text-to-speech) so you can build a local voice assistant. Worth doing if you have a USB mic.

## Resource cost

| Workload | RAM | CPU |
|---|---|---|
| Ollama idle (no model loaded) | ~80 MB | 0 % |
| Open WebUI idle | ~150 MB | 0 % |
| gemma3:1b loaded + generating | ~1.5 GB | 4 cores at 100 % |
| gemma3:4b loaded + generating | ~3.5 GB | 4 cores at 100 % |

## Production notes

- Models stay loaded in RAM after first use. `ollama ps` to see what's hot; `ollama stop <model>` to evict.
- Put the `ollama` data volume on the SSD — model files are big.
- Open WebUI exposes port 3000 with no auth until you sign up. If running on a Pi that's reachable from your LAN, do that immediately or bind 3000 to `127.0.0.1` and reverse-proxy via Caddy with HTTP auth.
- Pair with project 07 (free-llm-api-router) to offload to free cloud APIs when the Pi is busy → see project 08.
