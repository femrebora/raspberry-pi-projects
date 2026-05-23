"""Rate-limiter and base-provider unit tests."""
from __future__ import annotations

import time

import pytest

from llm_router.providers.base import (
    Provider,
    ProviderError,
    RateLimitedError,
    RateLimiter,
    to_openai_shape,
)


def test_rate_limiter_rpm_blocks_after_n():
    rl = RateLimiter(rpm=3)
    for _ in range(3):
        rl.check()
        rl.record()
    with pytest.raises(RateLimitedError):
        rl.check()


def test_rate_limiter_rpd_blocks_after_n():
    rl = RateLimiter(rpd=2)
    rl.check()
    rl.record()
    rl.check()
    rl.record()
    with pytest.raises(RateLimitedError):
        rl.check()


def test_rate_limiter_window_evicts_old():
    rl = RateLimiter(rpm=2)
    rl.minute_window.extend([time.time() - 120, time.time() - 90])
    # both are >60s old; check() should evict them and allow new requests
    rl.check()
    rl.record()
    rl.check()  # still under cap


def test_to_openai_shape_basic():
    out = to_openai_shape("acme", "model-x", "hello")
    assert out["object"] == "chat.completion"
    assert out["choices"][0]["message"]["content"] == "hello"
    assert out["model"] == "acme:model-x"


def test_provider_requires_api_key():
    class _P(Provider):
        name = "p"
    with pytest.raises(ValueError):
        _P(api_key="")


def test_provider_subclass_must_implement():
    class _P(Provider):
        name = "p"
    p = _P(api_key="x")
    with pytest.raises(NotImplementedError):
        p._request([{"role": "user", "content": "x"}], "m")


def test_subclass_catches_http_429_as_rate_limited(monkeypatch):
    import httpx

    class _P(Provider):
        name = "p"

        def _request(self, messages, model, **kwargs):
            resp = httpx.Response(429, request=httpx.Request("POST", "http://x"))
            raise httpx.HTTPStatusError("429", request=resp.request, response=resp)

    p = _P(api_key="x")
    with pytest.raises(RateLimitedError):
        p.chat([{"role": "user", "content": "hi"}])


def test_subclass_catches_http_500_as_provider_error():
    import httpx

    class _P(Provider):
        name = "p"

        def _request(self, messages, model, **kwargs):
            resp = httpx.Response(500, request=httpx.Request("POST", "http://x"))
            raise httpx.HTTPStatusError("500", request=resp.request, response=resp)

    p = _P(api_key="x")
    with pytest.raises(ProviderError):
        p.chat([{"role": "user", "content": "hi"}])
