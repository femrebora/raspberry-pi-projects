"""Tiny CLI: `python -m llm_router "hello"`."""
from __future__ import annotations

import argparse
import logging
import sys

from .router import Router, RouterError


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="llm-router")
    p.add_argument("prompt", nargs="?", help="User message to send.")
    p.add_argument("--provider", default=None, help="Pin a single provider (e.g. groq).")
    p.add_argument("--model", default=None, help="Pin a model (passed to the provider).")
    p.add_argument("--check", action="store_true", help="List reachable providers and exit.")
    p.add_argument("--verbose", "-v", action="store_true")
    args = p.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING,
        format="%(asctime)s  %(name)s  %(message)s",
    )

    try:
        router = Router.from_settings()
    except RouterError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    if args.check:
        print("Available providers (in order):")
        for n in router.available:
            print(f"  - {n}")
        return 0

    if not args.prompt:
        p.error("prompt required (or use --check)")

    model = "auto"
    if args.provider and args.model:
        model = f"{args.provider}:{args.model}"
    elif args.provider:
        model = f"{args.provider}:"  # router will fill in default

    try:
        resp = router.chat([{"role": "user", "content": args.prompt}], model=model)
    except RouterError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    print(resp["choices"][0]["message"]["content"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
