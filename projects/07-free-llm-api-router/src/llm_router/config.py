"""Environment-driven configuration."""
from __future__ import annotations

import os
from dataclasses import dataclass

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:  # dotenv is optional at runtime
    pass


@dataclass(frozen=True)
class Settings:
    groq_key: str | None
    gemini_key: str | None
    openrouter_key: str | None
    cerebras_key: str | None
    hf_key: str | None
    provider_order: list[str]
    request_timeout: float

    @classmethod
    def from_env(cls) -> Settings:
        return cls(
            groq_key=os.getenv("GROQ_API_KEY") or None,
            gemini_key=os.getenv("GEMINI_API_KEY") or None,
            openrouter_key=os.getenv("OPENROUTER_API_KEY") or None,
            cerebras_key=os.getenv("CEREBRAS_API_KEY") or None,
            hf_key=os.getenv("HF_API_KEY") or None,
            provider_order=[
                p.strip()
                for p in os.getenv(
                    "PROVIDER_ORDER", "groq,cerebras,gemini,openrouter,huggingface"
                ).split(",")
                if p.strip()
            ],
            request_timeout=float(os.getenv("REQUEST_TIMEOUT", "30")),
        )
