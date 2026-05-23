# 07 — Free-LLM-API router

A small Python package that turns five free LLM provider tiers into **one OpenAI-compatible endpoint**, with automatic failover and per-provider rate-limit awareness. Use it from any code that speaks OpenAI's chat API, and you almost never hit a limit.

## Why

- Each free tier is generous *enough* on its own (Groq 1 k/day, Cerebras 1 M tokens/day, Gemini 1 500/day, OpenRouter `:free` models, HF Inference).
- Stacked, you get effectively unlimited free inference for normal personal use, with the fastest provider tried first.
- Existing OpenAI-SDK code (Python, JS, anything) works against this router with no changes — just point `OPENAI_BASE_URL` at it.

## Supported providers

| Provider | Free-tier limits (May 2026) | Speed | Strength |
|---|---|---|---|
| **Groq** | 30 RPM, 1 000 RPD, 6 k TPM | ~315 tok/s | fastest |
| **Cerebras** | 30 RPM, 1 M tokens/day, 8 k ctx | very fast | high daily token budget |
| **Google Gemini** | 1 500 RPD, 1 M-token context | fast | huge context, frontier quality |
| **OpenRouter** | varies; `:free` models | medium | model variety |
| **Hugging Face Inference** | shared pool | slow | last resort, many open models |

## Setup

```bash
cd projects/07-free-llm-api-router

# 1. Get free API keys (no credit cards needed):
#    https://console.groq.com/keys
#    https://aistudio.google.com/apikey
#    https://openrouter.ai/keys
#    https://cloud.cerebras.ai
#    https://huggingface.co/settings/tokens
#
# 2. Paste them into .env (any missing key = provider skipped)
cp .env.example .env
$EDITOR .env

# 3a. Run as Python package (development)
python -m venv .venv && source .venv/bin/activate
pip install -e .
python -m llm_router "Hello in 5 words."

# 3b. Or run the OpenAI-compatible server in Docker (recommended for 24/7)
docker compose up -d
curl http://localhost:8088/v1/chat/completions \
  -H 'content-type: application/json' \
  -d '{"model":"auto","messages":[{"role":"user","content":"hi"}]}'
```

## Use from an OpenAI SDK client

```python
from openai import OpenAI
client = OpenAI(base_url="http://<pi-ip>:8088/v1", api_key="not-needed")
r = client.chat.completions.create(
    model="auto",
    messages=[{"role": "user", "content": "Summarise the EU AI Act in 3 bullets."}],
)
print(r.choices[0].message.content)
```

`model="auto"` lets the router pick. You can also pin a provider: `model="groq:llama-3.3-70b-versatile"`, `model="gemini:gemini-2.5-flash"`, etc.

## How failover works

1. Providers are tried in the order set by `PROVIDER_ORDER` in `.env` (default: groq → cerebras → gemini → openrouter → huggingface).
2. A provider is **skipped** if it has no key, or if its in-process counter says it's hit its RPM/RPD limit.
3. On any HTTP 429 / 5xx / network exception, the router moves to the next provider.
4. If *all* providers fail, an error is returned.

The rate-limit counter is **in-memory** and per-process. For multi-instance setups you'd want Redis; for one Pi it's plenty.

## CLI

```bash
# default: uses router order, prints response
python -m llm_router "Tell me a joke about Raspberry Pis."

# pin provider
python -m llm_router --provider groq "Tell me a joke about Raspberry Pis."

# show which providers are reachable
python -m llm_router --check
```

## Resource cost

| | Idle | Active |
|---|---|---|
| RAM | ~80 MB | ~150 MB |
| CPU | <1 % | <5 % per request |
| Image | ~120 MB | — |

## Production notes

- **The router does not stream.** Add streaming when you need it — the `Server-Sent Events` shape is already what OpenAI uses.
- **Keys never leave the Pi.** No telemetry, no third-party callbacks.
- **Be a good citizen.** These tiers are gifts; if you build something that handles >100 req/min sustained, get a paid plan. Hammering free tiers is how they go away for everyone.

## Tests

```bash
pip install pytest
pytest -q
```

Tests use stubbed HTTP responses; no network or real keys needed.
