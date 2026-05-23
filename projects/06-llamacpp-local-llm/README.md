# 06 — llama.cpp (raw, fastest local inference)

[`llama.cpp`](https://github.com/ggml-org/llama.cpp) is the C++ engine **under** Ollama. Running it directly trades ease-of-use for ~10–20% more tokens/sec on the Pi 5 and full control over flags (threads, context size, NEON tuning).

Pick this over Ollama when:

- You want the last bit of speed.
- You need a flag Ollama doesn't expose.
- You'd rather not run Docker for inference.

Pick Ollama (project 05) when you want auto-downloads, a UI, and zero CLI flags.

## Other alternative local servers (briefly)

| Server | When to consider it |
|---|---|
| **[LocalAI](https://localai.io)** | OpenAI-compatible, but **multi-modal** — chat + embeddings + TTS + STT + image gen in one process. Heavier than Ollama; great if you want one local endpoint to cover everything. |
| **[llamafile](https://github.com/Mozilla-Ocho/llamafile)** | Single self-contained binary that includes the weights — copy one file, run it. Perfect for sharing a tuned model with non-technical people. |

See [`../05-ollama-local-llm/alt-models.md`](../05-ollama-local-llm/alt-models.md) for the alternative-models matrix that applies to all three servers.

## Dependencies

| Thing | Why |
|---|---|
| `build-essential`, `cmake`, `git` | compile llama.cpp |
| `libcurl4-openssl-dev` | optional: lets `llama-server` download models on demand |

## Setup

```bash
sudo apt update
sudo apt install -y build-essential cmake git libcurl4-openssl-dev

bash projects/06-llamacpp-local-llm/install.sh
```

This clones `llama.cpp`, builds it with NEON SIMD (the Pi 5's CPU vector extensions), and downloads one starter model (Gemma 3 1B Q4_K_M, ~700 MB).

## Run a one-shot prompt

```bash
~/llama.cpp/build/bin/llama-cli \
  -m ~/llama.cpp/models/gemma-3-1b-it-Q4_K_M.gguf \
  -p "Explain how a Raspberry Pi differs from a regular PC in 3 sentences." \
  -n 200 -t 4
```

## Run an OpenAI-compatible HTTP server

```bash
bash projects/06-llamacpp-local-llm/run-server.sh
# now POST to http://localhost:8080/v1/chat/completions
```

It's drop-in compatible with anything that speaks the OpenAI API — including project 07's router and project 08's hybrid app.

## Benchmark your build

```bash
bash projects/06-llamacpp-local-llm/benchmark.sh
```

Prints prompt-processing and generation tokens/sec.

## Resource cost

| Workload | RAM | CPU |
|---|---|---|
| `llama-server` idle | ~50 MB | 0 % |
| Generating with `gemma-3-1b-Q4_K_M` | ~1.4 GB | 4 cores at 100 % |
| Generating with `gemma-3-4b-Q4_K_M` | ~3.3 GB | 4 cores at 100 % |

## Production notes

- Always pass `-t 4` (or `--threads 4`) on a Pi 5; using `-t 8` (SMT count from `nproc` on Pi 5 = 4, no SMT) doesn't help.
- `-c` (context length) eats RAM linearly. 2048 is plenty for most chat.
- Add `--mlock` if you have free RAM to keep weights pinned (prevents swap-out under memory pressure from other containers).
- Want it auto-restarted? Drop the systemd unit from [project 09](../09-24-7-ops/) and point it at `llama-server`.
