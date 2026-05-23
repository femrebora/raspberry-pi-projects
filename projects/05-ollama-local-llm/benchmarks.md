# Pi 5 8 GB LLM benchmarks (May 2026)

Measured on Raspberry Pi 5 (8 GB), active cooler, Pi OS 64-bit Bookworm, NVMe SSD, Ollama latest. Generation speed for `"Write a short paragraph about the Roman Empire."` averaged over 5 runs after model load.

| Model | Size on disk | RAM in use | Tokens/sec | Notes |
|---|---|---|---|---|
| `tinyllama` (1.1B Q4_K_M) | 0.7 GB | ~0.9 GB | 25–30 | Smallest, English-only, OK for one-liners only |
| `gemma3:1b` | 1.0 GB | ~1.5 GB | 18–22 | **Recommended for chat speed** |
| `qwen2.5:0.5b` | 0.4 GB | ~0.7 GB | 28–35 | Surprisingly capable; multilingual incl. TR |
| `qwen2.5:1.5b` | 1.0 GB | ~1.4 GB | 12–15 | Best small coder |
| `phi3:mini` (3.8B Q4) | 2.4 GB | ~3.2 GB | 5–7 | Best instruction-following at this size |
| `gemma3:4b` (Q4_K_M) | 2.8 GB | ~3.5 GB | 8–11 | **Best quality at acceptable speed** |
| `llama3.2:3b` | 2.0 GB | ~2.7 GB | 8–10 | Solid all-rounder |
| `mistral:7b` (Q4) | 4.4 GB | ~5.2 GB | 2–3 | Borderline; long prompts will swap |

## How to reproduce

```bash
docker exec -it ollama ollama run gemma3:1b --verbose "Write a short paragraph about the Roman Empire."
```

Look for `eval rate: XX.XX tokens/s` at the end.

## Practical takeaways

- **Sweet spot for chat: `gemma3:1b`** — fast enough to feel conversational.
- **Sweet spot for quality: `gemma3:4b`** — 3.5 GB RAM, half the speed, much smarter.
- **7B models work** but are too slow for interactive use (~3 tok/s). Use them in batch jobs or pair with project 08 to fall back to Groq for interactive needs.
- Loading a model the first time takes 5–20 seconds. Keep frequently used models warm; cold-load is a noticeable UX delay.
- llama.cpp (project 06) is 10–20% faster than Ollama on the same model thanks to NEON/SVE tuning.
