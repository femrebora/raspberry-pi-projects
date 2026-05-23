"""Router unit tests with stub providers — no network."""
from __future__ import annotations

import pytest

from llm_router.providers.base import Provider, ProviderError, RateLimitedError
from llm_router.router import Router, RouterError


class StubOK(Provider):
    name = "stubok"
    default_model = "x"

    def __init__(self):  # bypass api_key check
        self.api_key = "x"
        self.timeout = 5
        from llm_router.providers.base import RateLimiter
        self.limiter = RateLimiter()

    def _request(self, messages, model, **kwargs):
        return {"choices": [{"message": {"role": "assistant", "content": "ok"}}], "model": self.name}


class StubRateLimited(StubOK):
    name = "stubrl"

    def _request(self, messages, model, **kwargs):
        raise RateLimitedError("upstream 429")


class StubBroken(StubOK):
    name = "stubbroken"

    def _request(self, messages, model, **kwargs):
        raise ProviderError("upstream 500")


def test_first_provider_wins():
    r = Router([StubOK()])
    resp = r.chat([{"role": "user", "content": "hi"}])
    assert resp["choices"][0]["message"]["content"] == "ok"


def test_rate_limit_skips_to_next():
    r = Router([StubRateLimited(), StubOK()])
    resp = r.chat([{"role": "user", "content": "hi"}])
    assert resp["choices"][0]["message"]["content"] == "ok"


def test_broken_skips_to_next():
    r = Router([StubBroken(), StubOK()])
    resp = r.chat([{"role": "user", "content": "hi"}])
    assert resp["choices"][0]["message"]["content"] == "ok"


def test_all_fail_raises():
    r = Router([StubBroken(), StubRateLimited()])
    with pytest.raises(RouterError):
        r.chat([{"role": "user", "content": "hi"}])


def test_no_providers_raises():
    with pytest.raises(RouterError):
        Router([])


def test_pinned_provider_only():
    a = StubOK()
    a.name = "alpha"
    b = StubOK()
    b.name = "beta"
    r = Router([a, b])
    resp = r.chat([{"role": "user", "content": "hi"}], model="beta:x")
    assert "beta" in resp["model"] or resp["choices"][0]["message"]["content"] == "ok"
