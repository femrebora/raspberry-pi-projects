"""FastAPI app exposing an OpenAI-compatible /v1/chat/completions endpoint."""
from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from .router import Router, RouterError

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(name)s  %(message)s")

app = FastAPI(title="llm-router", version="0.1.0")
_router: Router | None = None


def _get_router() -> Router:
    global _router
    if _router is None:
        _router = Router.from_settings()
    return _router


class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: str = "auto"
    messages: list[Message]
    temperature: float | None = None
    max_tokens: int | None = None


@app.get("/health")
def health() -> dict[str, Any]:
    try:
        return {"status": "ok", "providers": _get_router().available}
    except RouterError as e:
        return {"status": "degraded", "error": str(e)}


@app.get("/v1/models")
def models() -> dict[str, Any]:
    try:
        names = _get_router().available
    except RouterError:
        names = []
    return {
        "object": "list",
        "data": [{"id": "auto", "object": "model"}]
        + [{"id": n, "object": "model"} for n in names],
    }


@app.post("/v1/chat/completions")
def chat(req: ChatRequest) -> dict[str, Any]:
    messages = [{"role": m.role, "content": m.content} for m in req.messages]
    kwargs: dict[str, Any] = {}
    if req.temperature is not None:
        kwargs["temperature"] = req.temperature
    if req.max_tokens is not None:
        kwargs["max_tokens"] = req.max_tokens
    try:
        return _get_router().chat(messages, model=req.model, **kwargs)
    except RouterError as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
