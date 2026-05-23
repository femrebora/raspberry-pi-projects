"""OpenAI-compatible router across free LLM API tiers."""
from .router import Router, RouterError

__all__ = ["Router", "RouterError"]
__version__ = "0.1.0"
