# Alternative open-source models for the Pi 5 8 GB

Beyond the chat-focused models in [`benchmarks.md`](benchmarks.md), here are the best small models per task in May 2026. Every name is the **exact tag** you can `ollama pull`.

## Coding

| Model | Pull tag | Size | Notes |
|---|---|---|---|
| **Qwen 2.5 Coder 1.5B** | `qwen2.5-coder:1.5b` | ~1 GB | Best coder at this size; ~13 tok/s on Pi 5 |
| Qwen 2.5 Coder 3B | `qwen2.5-coder:3b` | ~2 GB | Stronger; ~8 tok/s |
| DeepSeek Coder v2 1.5B | `deepseek-coder-v2:1.5b` | ~1 GB | Good for autocomplete, 338 languages |
| CodeGemma 2B | `codegemma:2b` | ~1.5 GB | Google's coder; balanced |
| StarCoder2 3B | `starcoder2:3b` | ~2 GB | Strong on niche languages |

Pair with **Aider** (project 13): `aider --model ollama/qwen2.5-coder:1.5b`.

## Reasoning

| Model | Pull tag | Size | Notes |
|---|---|---|---|
| **DeepSeek-R1 distilled 1.5B** | `deepseek-r1:1.5b` | ~1.1 GB | Chain-of-thought for the Pi; ~14 tok/s |
| DeepSeek-R1 distilled 7B | `deepseek-r1:7b` | ~4.7 GB | Borderline; ~3 tok/s, much better quality |
| Phi-3 Mini Reasoning | `phi3:mini` | ~2.4 GB | Microsoft, strong at small size |

## Vision (image + text in)

| Model | Pull tag | Size | Notes |
|---|---|---|---|
| **Moondream 2** | `moondream:1.8b-v2-q4` | ~1.6 GB | Tiny VLM; image captioning, OCR-ish |
| LLaVA Phi3 | `llava-phi3` | ~2.9 GB | Conversational image understanding |
| Llama 3.2 Vision 11B | `llama3.2-vision:11b` | ~7.9 GB | Too big for live use; works for batch |

## Multilingual (incl. Turkish, Chinese, Japanese)

| Model | Pull tag | Size | Notes |
|---|---|---|---|
| **Qwen 2.5 1.5B** | `qwen2.5:1.5b` | ~1 GB | Strong Turkish/Chinese; ~13 tok/s |
| Qwen 2.5 3B | `qwen2.5:3b` | ~2 GB | Stronger, slower |
| Gemma 3 4B | `gemma3:4b` | ~2.8 GB | Multilingual; ~8 tok/s |
| Aya 23 8B | `aya:8b` | ~5 GB | 23 languages incl. TR; borderline RAM |

## Embeddings (RAG, search)

| Model | Pull tag | Size | Output dim |
|---|---|---|---|
| **nomic-embed-text** | `nomic-embed-text` | ~270 MB | 768 |
| mxbai-embed-large | `mxbai-embed-large` | ~670 MB | 1024 |
| all-minilm | `all-minilm` | ~46 MB | 384 |

Use via Ollama's `/api/embeddings` endpoint. Pair with a vector DB like Chroma or Qdrant (both work in Docker on the Pi).

## Cross-cutting

- **All of these run via Ollama (project 05)**. For 10–20% more speed, the same GGUF weights run under **llama.cpp** (project 06).
- **Quantisation tip:** `:1.5b` (no quant suffix) is Q4_0 in Ollama by default. Specify `:1.5b-instruct-q5_K_M` for higher quality at ~25% more RAM.
- **First-time pulls are big.** Put the Ollama data volume on the SSD (the `docker-compose.yml` in project 05 already uses a named volume that ends up there if your Docker root is on SSD).

## Alternative local LLM servers

Ollama isn't the only game in town:

| Server | What it adds | When to switch |
|---|---|---|
| **[llama.cpp](https://github.com/ggml-org/llama.cpp)** (project 06) | Raw speed, full flag control | You want every last tok/s |
| **[LocalAI](https://localai.io)** | OpenAI-compatible, **multi-modal** (chat + embeddings + TTS + STT + image gen) in one server | You want one local endpoint covering more than chat |
| **[llamafile](https://github.com/Mozilla-Ocho/llamafile)** | Single self-contained binary that includes the weights — runs anywhere | You want zero-install for sharing/demoing |
| **[vLLM](https://github.com/vllm-project/vllm)** | Server-grade throughput | You have a real GPU (not a Pi use case) |

For the Pi: **Ollama** is the default for ease, **llama.cpp** for speed, **LocalAI** if you need TTS/STT/embeddings all in one process, **llamafile** for portability.
