"""OpenRouter: OpenAI-shape API to many community-hosted free models."""
from __future__ import annotations

from typing import Any

import httpx

from .base import Provider


class OpenRouter(Provider):
    name = "openrouter"
    # Pick a known free-tier model (the `:free` suffix marks them).
    default_model = "meta-llama/llama-3.3-8b-instruct:free"
    # No documented universal cap; per-model caps apply. Use a soft per-minute throttle.
    rpm = 30
    rpd = None

    def _request(self, messages: list[dict[str, str]], model: str, **kwargs: Any) -> dict[str, Any]:
        with httpx.Client(timeout=self.timeout) as client:
            r = client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    # Optional but recommended by OpenRouter for free-tier prioritisation.
                    "HTTP-Referer": "https://github.com/femrebora/raspberry-pi-projects",
                    "X-Title": "raspberry-pi-projects",
                },
                json={"model": model, "messages": messages, **kwargs},
            )
            r.raise_for_status()
            data = r.json()
            data.setdefault("model", f"{self.name}:{model}")
            return data
