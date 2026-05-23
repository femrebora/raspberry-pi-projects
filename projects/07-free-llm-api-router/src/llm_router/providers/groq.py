"""Groq: OpenAI-shape chat completions, fast Llama / Gemma models."""
from __future__ import annotations

from typing import Any

import httpx

from .base import Provider


class Groq(Provider):
    name = "groq"
    default_model = "llama-3.3-70b-versatile"
    rpm = 30
    rpd = 1000

    def _request(self, messages: list[dict[str, str]], model: str, **kwargs: Any) -> dict[str, Any]:
        with httpx.Client(timeout=self.timeout) as client:
            r = client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={"model": model, "messages": messages, **kwargs},
            )
            r.raise_for_status()
            data = r.json()
            data.setdefault("model", f"{self.name}:{model}")
            return data
