"""Google Gemini via AI Studio. Not OpenAI-shape upstream; we adapt."""
from __future__ import annotations

from typing import Any

import httpx

from .base import Provider, ProviderError, to_openai_shape


class Gemini(Provider):
    name = "gemini"
    default_model = "gemini-2.5-flash"
    rpm = 15           # generous default; varies by model
    rpd = 1500

    def _request(self, messages: list[dict[str, str]], model: str, **kwargs: Any) -> dict[str, Any]:
        # Gemini expects {contents: [{role, parts: [{text}]}]} with role 'user' or 'model'.
        contents = []
        for m in messages:
            role = "model" if m["role"] == "assistant" else "user"
            contents.append({"role": role, "parts": [{"text": m.get("content", "")}]})

        with httpx.Client(timeout=self.timeout) as client:
            r = client.post(
                f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
                params={"key": self.api_key},
                json={"contents": contents},
            )
            r.raise_for_status()
            data = r.json()
        try:
            text = data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError) as e:
            raise ProviderError(f"gemini: unexpected response shape: {str(data)[:200]}") from e
        return to_openai_shape(self.name, model, text)
