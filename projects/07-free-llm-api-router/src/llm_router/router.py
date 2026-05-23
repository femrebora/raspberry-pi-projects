"""The Router: tries providers in order, skips rate-limited or broken ones."""
from __future__ import annotations

import logging
from typing import Any

from .config import Settings
from .providers import (
    Cerebras,
    Gemini,
    Groq,
    HuggingFace,
    OpenRouter,
    Provider,
    ProviderError,
    RateLimitedError,
)

log = logging.getLogger("llm_router")

_PROVIDER_CLASSES = {
    "groq": Groq,
    "cerebras": Cerebras,
    "gemini": Gemini,
    "openrouter": OpenRouter,
    "huggingface": HuggingFace,
}


class RouterError(Exception):
    """Every provider failed or none were configured."""


class Router:
    def __init__(self, providers: list[Provider]):
        if not providers:
            raise RouterError("no providers configured (set at least one API key in .env)")
        self.providers = providers

    @classmethod
    def from_settings(cls, settings: Settings | None = None) -> Router:
        s = settings or Settings.from_env()
        key_map = {
            "groq": s.groq_key,
            "cerebras": s.cerebras_key,
            "gemini": s.gemini_key,
            "openrouter": s.openrouter_key,
            "huggingface": s.hf_key,
        }
        providers: list[Provider] = []
        for name in s.provider_order:
            cls_ = _PROVIDER_CLASSES.get(name)
            key = key_map.get(name)
            if cls_ is None:
                log.warning("Unknown provider %r in PROVIDER_ORDER, skipping", name)
                continue
            if not key:
                log.info("No key for %s, skipping", name)
                continue
            providers.append(cls_(api_key=key, timeout=s.request_timeout))
        return cls(providers)

    def chat(self, messages: list[dict[str, str]], model: str = "auto",
             **kwargs: Any) -> dict[str, Any]:
        # model can be "auto" or "<provider>:<model>" to pin.
        pinned_provider: str | None = None
        pinned_model: str | None = None
        if model != "auto" and ":" in model:
            pinned_provider, pinned_model = model.split(":", 1)

        last_err: Exception | None = None
        for p in self.providers:
            if pinned_provider and p.name != pinned_provider:
                continue
            try:
                return p.chat(messages, model=pinned_model, **kwargs)
            except RateLimitedError as e:
                log.info("%s rate-limited (%s), trying next", p.name, e)
                last_err = e
            except ProviderError as e:
                log.warning("%s failed: %s", p.name, e)
                last_err = e
        raise RouterError(f"all providers failed; last error: {last_err}")

    @property
    def available(self) -> list[str]:
        return [p.name for p in self.providers]
