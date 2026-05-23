"""Provider base class + a simple in-process rate-limit counter."""
from __future__ import annotations

import time
from collections import deque
from dataclasses import dataclass, field
from typing import Any

import httpx


class ProviderError(Exception):
    """Any failure that means 'try the next provider'."""


class RateLimitedError(ProviderError):
    """Local counter or upstream 429 says we've hit a cap."""


@dataclass
class RateLimiter:
    """Tracks request timestamps per minute and per day."""

    rpm: int | None = None
    rpd: int | None = None
    minute_window: deque[float] = field(default_factory=deque)
    day_window: deque[float] = field(default_factory=deque)

    def check(self) -> None:
        now = time.time()
        self._evict(self.minute_window, now - 60)
        self._evict(self.day_window, now - 86400)
        if self.rpm is not None and len(self.minute_window) >= self.rpm:
            raise RateLimitedError(f"per-minute cap ({self.rpm}) reached")
        if self.rpd is not None and len(self.day_window) >= self.rpd:
            raise RateLimitedError(f"per-day cap ({self.rpd}) reached")

    def record(self) -> None:
        now = time.time()
        self.minute_window.append(now)
        self.day_window.append(now)

    @staticmethod
    def _evict(window: deque[float], cutoff: float) -> None:
        while window and window[0] < cutoff:
            window.popleft()


class Provider:
    """Base provider. Subclasses implement `_request` returning OpenAI-shaped JSON."""

    name: str = "base"
    default_model: str = ""
    rpm: int | None = None
    rpd: int | None = None

    def __init__(self, api_key: str, timeout: float = 30.0):
        if not api_key:
            raise ValueError(f"{self.name}: api_key is required")
        self.api_key = api_key
        self.timeout = timeout
        self.limiter = RateLimiter(rpm=self.rpm, rpd=self.rpd)

    def chat(self, messages: list[dict[str, str]], model: str | None = None,
             **kwargs: Any) -> dict[str, Any]:
        self.limiter.check()
        try:
            result = self._request(messages, model or self.default_model, **kwargs)
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:
                raise RateLimitedError(f"{self.name} upstream 429") from e
            raise ProviderError(
                f"{self.name} HTTP {e.response.status_code}: {e.response.text[:200]}"
            ) from e
        except httpx.HTTPError as e:
            raise ProviderError(f"{self.name} network error: {e}") from e
        self.limiter.record()
        return result

    # Subclasses override.
    def _request(self, messages: list[dict[str, str]], model: str, **kwargs: Any) -> dict[str, Any]:
        raise NotImplementedError


def to_openai_shape(provider: str, model: str, text: str) -> dict[str, Any]:
    """Wrap raw text into a minimal OpenAI chat-completion response."""
    return {
        "id": f"chatcmpl-{provider}-{int(time.time() * 1000)}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": f"{provider}:{model}",
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": text},
                "finish_reason": "stop",
            }
        ],
        "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
    }
