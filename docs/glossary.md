# Glossary

Terms used across this repo, kept short.

| Term | Meaning |
|---|---|
| **ARM64 / aarch64** | The Pi 5's CPU architecture. Make sure binaries you download say `arm64`, not `amd64`. |
| **Caddy** | A web server / reverse proxy with automatic HTTPS via Let's Encrypt. |
| **CGNAT** | Carrier-grade NAT. Your ISP shares one public IP across many customers, so port-forwarding doesn't reach you. |
| **Compose** | `docker compose` — defines multi-container apps in `docker-compose.yml`. |
| **GGUF** | The quantised binary format llama.cpp uses for models. |
| **Hugging Face** | Hub for open-source models. Lots of GGUF files live there. |
| **llama.cpp** | C++ inference engine for LLMs. Fast on Pi. |
| **MagicDNS** | Tailscale feature: each device gets a hostname like `pi5.tailnet.ts.net`. |
| **Ollama** | Friendly wrapper around llama.cpp; one-line model install, OpenAI-compatible API. |
| **OpenAI-compatible** | An HTTP API that mimics `api.openai.com/v1/...`. Lets you swap providers without changing client code. |
| **Quantisation** | Shrinking model weights (e.g., 16-bit → 4-bit). `Q4_K_M` is the typical sweet spot for Pi. |
| **Reverse proxy** | A web server that sits in front of your apps and forwards requests. Lets Caddy/cloudflared handle TLS once. |
| **TPS / tok/s** | Tokens per second — how fast a model generates text. |
| **TPM / RPM / RPD** | Tokens-per-minute / requests-per-minute / requests-per-day — common rate-limit units. |
| **Tunnel** | Outbound persistent connection from the Pi to a cloud provider (Cloudflare, Tailscale) that lets inbound traffic reach you without opening ports. |
| **Watchtower** | Docker container that pulls newer images and recreates running containers automatically. |
| **ufw** | Uncomplicated Firewall — friendly wrapper around `iptables`/`nftables`. |
