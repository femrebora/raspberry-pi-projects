"""Cerebras Inference: OpenAI-shape, very fast, 1M tokens/day free."""
from __future__ import annotations

from typing import Any

import httpx

from .base import Provider


class Cerebras(Provider):
    name = "cerebras"
    default_model = "llama-3.3-70b"
    rpm = 30
    rpd = None  # token-based daily cap; not request-based

    def _request(self, messages: list[dict[str, str]], model: str, **kwargs: Any) -> dict[str, Any]:
        with httpx.Client(timeout=self.timeout) as client:
            r = client.post(
                "https://api.cerebras.ai/v1/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={"model": model, "messages": messages, **kwargs},
            )
            r.raise_for_status()
            data = r.json()
            data.setdefault("model", f"{self.name}:{model}")
            return data
