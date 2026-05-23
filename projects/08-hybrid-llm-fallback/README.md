# 08 — Hybrid LLM (local first, free cloud as fallback)

The pragmatic answer to "I want 24/7 free LLM on a Pi": **try Ollama locally; if it's busy or unavailable, fall back to the free-API router from project 07**.

This is what you actually want for an app or assistant:

- Most queries are answered locally (free, private, fast for small models).
- When the Pi is overloaded, doing voice transcription, serving the website, etc., the request transparently goes to Groq / Gemini / Cerebras instead.
- If the cloud tiers are all rate-limited too, you get a clear error.

## Dependencies

- Project 05 ([Ollama](../05-ollama-local-llm/)) running on `http://ollama:11434` (or change `OLLAMA_URL`)
- Project 07 ([free-llm-api-router](../07-free-llm-api-router/)) running on `http://router:8088` (or change `ROUTER_URL`)

If neither is set, the app degrades gracefully but won't be useful.

## Setup

```bash
cd projects/08-hybrid-llm-fallback
cp .env.example .env
# edit .env: confirm OLLAMA_URL and ROUTER_URL are reachable from this container
docker compose up -d --build
```

Test it:

```bash
curl http://localhost:8090/chat -d '{"prompt":"Two-sentence summary of how a Pi 5 differs from a Pi 4."}'
```

The response includes a `via` field telling you which backend served it (`local` or `cloud`).

## How the decision is made

1. POST `/chat` with `{prompt}`.
2. The app sends a quick `GET /api/tags` to Ollama with a 1 s timeout.
3. If Ollama responds and isn't already serving another generate, **go local**.
4. Else, post to the router's `/v1/chat/completions` with `model="auto"`. **Go cloud**.
5. On any failure of the chosen path, retry the other path once before giving up.

## Resource cost

| | RAM | CPU |
|---|---|---|
| The hybrid app itself | ~80 MB | <1 % |
| The real cost is wherever it routes | — | — |

## Why not always cloud?

- Free tiers have daily caps. The 1 500 Gemini req/day or 1 k Groq req/day disappear quickly if you're building anything chatty.
- Local is private — no data leaves your network for personal queries.
- Local has zero per-request latency to a remote service; if Ollama is warm, it can actually beat a cold cloud round-trip on a fast LAN.

## Why not always local?

- A 1B / 3B model can't match Gemini 2.5 Flash on hard reasoning.
- The Pi can only run one heavy thing at a time. If you're recording video and someone hits the chat, local will lag.

Hybrid gives you the best of both with one endpoint.
