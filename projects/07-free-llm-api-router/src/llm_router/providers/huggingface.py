"""Hugging Face Inference API — last-resort fallback, lots of models."""
from __future__ import annotations

from typing import Any

import httpx

from .base import Provider, to_openai_shape


class HuggingFace(Provider):
    name = "huggingface"
    default_model = "meta-llama/Llama-3.2-3B-Instruct"
    rpm = None
    rpd = None

    def _request(self, messages: list[dict[str, str]], model: str, **kwargs: Any) -> dict[str, Any]:
        # HF Inference API for text-generation expects {"inputs": "..."}; we render messages
        # using the model's chat template via the dedicated chat endpoint.
        with httpx.Client(timeout=self.timeout) as client:
            r = client.post(
                f"https://api-inference.huggingface.co/models/{model}/v1/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={"model": model, "messages": messages, **kwargs},
            )
            r.raise_for_status()
            data = r.json()
        # If it answered in OpenAI shape, pass through; otherwise wrap.
        if "choices" in data:
            data.setdefault("model", f"{self.name}:{model}")
            return data
        text = data[0]["generated_text"] if isinstance(data, list) else str(data)
        return to_openai_shape(self.name, model, text)
