"""Hybrid LLM endpoint: try local Ollama first, fall back to the cloud router."""
from __future__ import annotations

import logging
import os
from typing import Literal

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(name)s  %(message)s")
log = logging.getLogger("hybrid")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434").rstrip("/")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:1b")
ROUTER_URL = os.getenv("ROUTER_URL", "http://localhost:8088").rstrip("/")
OLLAMA_TIMEOUT = float(os.getenv("OLLAMA_TIMEOUT", "30"))
ROUTER_TIMEOUT = float(os.getenv("ROUTER_TIMEOUT", "30"))

app = FastAPI(title="hybrid-llm", version="0.1.0")


class ChatRequest(BaseModel):
    prompt: str
    prefer: Literal["local", "cloud", "auto"] = "auto"


class ChatResponse(BaseModel):
    text: str
    via: Literal["local", "cloud"]


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "ollama": OLLAMA_URL,
        "router": ROUTER_URL,
    }


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    order: list[str]
    if req.prefer == "local":
        order = ["local", "cloud"]
    elif req.prefer == "cloud":
        order = ["cloud", "local"]
    else:
        order = ["local", "cloud"] if _local_reachable() else ["cloud", "local"]

    last_err: str | None = None
    for backend in order:
        try:
            text = _ask_local(req.prompt) if backend == "local" else _ask_cloud(req.prompt)
            return ChatResponse(text=text, via=backend)  # type: ignore[arg-type]
        except Exception as e:
            last_err = f"{backend}: {e}"
            log.warning("%s failed: %s", backend, e)
    raise HTTPException(status_code=503, detail=f"both backends failed; last: {last_err}")


def _local_reachable() -> bool:
    try:
        with httpx.Client(timeout=1.0) as c:
            return c.get(f"{OLLAMA_URL}/api/tags").status_code == 200
    except httpx.HTTPError:
        return False


def _ask_local(prompt: str) -> str:
    with httpx.Client(timeout=OLLAMA_TIMEOUT) as c:
        r = c.post(
            f"{OLLAMA_URL}/api/generate",
            json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False},
        )
        r.raise_for_status()
        return r.json()["response"]


def _ask_cloud(prompt: str) -> str:
    with httpx.Client(timeout=ROUTER_TIMEOUT) as c:
        r = c.post(
            f"{ROUTER_URL}/v1/chat/completions",
            json={"model": "auto", "messages": [{"role": "user", "content": prompt}]},
        )
        r.raise_for_status()
        return r.json()["choices"][0]["message"]["content"]
