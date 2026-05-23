"""Tiny FastAPI + HTMX dashboard for raspberry-pi-projects."""
from __future__ import annotations

import os
import re
import secrets
import subprocess
from pathlib import Path
from typing import Any

import httpx
from fastapi import Depends, FastAPI, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.templating import Jinja2Templates

REPO_ROOT = Path(os.getenv("REPO_ROOT", "/repo"))
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434").rstrip("/")
ROUTER_URL = os.getenv("ROUTER_URL", "http://localhost:8088").rstrip("/")
PANEL_USER = os.getenv("PANEL_USER", "admin")
PANEL_PASSWORD = os.getenv("PANEL_PASSWORD", "please-change-me")

app = FastAPI(title="pi-control-panel", version="0.1.0")
templates = Jinja2Templates(directory="templates")
security = HTTPBasic()


def require_auth(creds: HTTPBasicCredentials = Depends(security)) -> str:
    if not (
        secrets.compare_digest(creds.username, PANEL_USER)
        and secrets.compare_digest(creds.password, PANEL_PASSWORD)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="bad credentials",
            headers={"WWW-Authenticate": "Basic"},
        )
    return creds.username


# ---------------------------------------------------------------------------
# project discovery
# ---------------------------------------------------------------------------
def discover_projects() -> list[dict[str, Any]]:
    """Find every projects/NN-name/docker-compose.yml (ignoring *.example.*)."""
    projects_dir = REPO_ROOT / "projects"
    if not projects_dir.exists():
        return []
    out: list[dict[str, Any]] = []
    for d in sorted(p for p in projects_dir.iterdir() if p.is_dir()):
        compose = None
        for candidate in ("docker-compose.yml", "docker-compose.yaml"):
            f = d / candidate
            if f.exists():
                compose = f
                break
        if compose is None:
            # Project has no compose file (e.g. script-only project 13).
            continue
        out.append(
            {
                "name": d.name,
                "dir": d,
                "compose": compose,
                "has_env": (d / ".env.example").exists(),
            }
        )
    return out


def compose_status(compose: Path) -> str:
    """Return 'up' / 'down' / 'partial'."""
    try:
        r = subprocess.run(
            ["docker", "compose", "-f", str(compose), "ps", "--format", "{{.State}}"],
            capture_output=True, text=True, timeout=10, check=False,
        )
        if r.returncode != 0:
            return "unknown"
        states = [s for s in r.stdout.strip().splitlines() if s]
        if not states:
            return "down"
        if all(s == "running" for s in states):
            return "up"
        return "partial"
    except (subprocess.SubprocessError, FileNotFoundError):
        return "unknown"


# ---------------------------------------------------------------------------
# dashboard
# ---------------------------------------------------------------------------
@app.get("/", response_class=HTMLResponse)
def index(request: Request, _: str = Depends(require_auth)) -> HTMLResponse:
    projects = discover_projects()
    for p in projects:
        p["status"] = compose_status(p["compose"])
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "projects": projects,
            "ollama_url": OLLAMA_URL,
            "router_url": ROUTER_URL,
        },
    )


@app.get("/health")
def health() -> dict[str, Any]:
    return {"status": "ok", "repo": str(REPO_ROOT), "projects": len(discover_projects())}


# ---------------------------------------------------------------------------
# compose actions
# ---------------------------------------------------------------------------
def _project_or_404(name: str) -> dict[str, Any]:
    for p in discover_projects():
        if p["name"] == name:
            return p
    raise HTTPException(404, f"unknown project: {name}")


@app.post("/project/{name}/up")
def project_up(name: str, _: str = Depends(require_auth)) -> RedirectResponse:
    p = _project_or_404(name)
    subprocess.run(
        ["docker", "compose", "-f", str(p["compose"]), "up", "-d"],
        capture_output=True, text=True, timeout=120, check=False,
    )
    return RedirectResponse("/", status_code=303)


@app.post("/project/{name}/down")
def project_down(name: str, _: str = Depends(require_auth)) -> RedirectResponse:
    p = _project_or_404(name)
    subprocess.run(
        ["docker", "compose", "-f", str(p["compose"]), "down"],
        capture_output=True, text=True, timeout=60, check=False,
    )
    return RedirectResponse("/", status_code=303)


@app.get("/project/{name}/logs", response_class=HTMLResponse)
def project_logs(request: Request, name: str, _: str = Depends(require_auth)) -> HTMLResponse:
    p = _project_or_404(name)
    r = subprocess.run(
        ["docker", "compose", "-f", str(p["compose"]), "logs", "--tail=200", "--no-color"],
        capture_output=True, text=True, timeout=15, check=False,
    )
    return templates.TemplateResponse(
        "logs.html", {"request": request, "name": name, "logs": r.stdout or r.stderr}
    )


# ---------------------------------------------------------------------------
# env editor
# ---------------------------------------------------------------------------
ENV_LINE = re.compile(r"^\s*([A-Z_][A-Z0-9_]*)\s*=(.*)$")


def _read_env(path: Path) -> dict[str, str]:
    """Return {KEY: VALUE} parsed from a .env file (empty dict if missing)."""
    if not path.exists():
        return {}
    out: dict[str, str] = {}
    for line in path.read_text().splitlines():
        if not line or line.lstrip().startswith("#"):
            continue
        m = ENV_LINE.match(line)
        if m:
            out[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return out


def _read_env_keys(example_path: Path) -> list[tuple[str, str]]:
    """Return [(KEY, comment_line_above), ...] from a .env.example."""
    keys: list[tuple[str, str]] = []
    if not example_path.exists():
        return keys
    last_comment = ""
    for line in example_path.read_text().splitlines():
        if line.lstrip().startswith("#"):
            last_comment = line.lstrip("# ").strip()
            continue
        m = ENV_LINE.match(line)
        if m:
            keys.append((m.group(1), last_comment))
            last_comment = ""
    return keys


SECRET_TOKENS = ("KEY", "TOKEN", "PASSWORD", "SECRET", "AUTHKEY")


def _is_secret(k: str) -> bool:
    return any(tok in k.upper() for tok in SECRET_TOKENS)


@app.get("/project/{name}/env", response_class=HTMLResponse)
def env_form(request: Request, name: str, _: str = Depends(require_auth)) -> HTMLResponse:
    p = _project_or_404(name)
    if not p["has_env"]:
        raise HTTPException(404, "no .env.example for this project")
    keys = _read_env_keys(p["dir"] / ".env.example")
    current = _read_env(p["dir"] / ".env")
    rows = [
        {
            "key": k,
            "comment": c,
            "value": current.get(k, ""),
            "is_secret": _is_secret(k),
        }
        for k, c in keys
    ]
    return templates.TemplateResponse(
        "env.html",
        {"request": request, "name": name, "rows": rows},
    )


@app.post("/project/{name}/env")
async def env_save(request: Request, name: str, _: str = Depends(require_auth)) -> RedirectResponse:
    p = _project_or_404(name)
    if not p["has_env"]:
        raise HTTPException(404, "no .env.example for this project")
    form = await request.form()
    lines: list[str] = ["# Written by pi-control-panel — keep me out of git."]
    for k, _ in _read_env_keys(p["dir"] / ".env.example"):
        v = form.get(k, "")
        # Quote values containing spaces or special chars.
        if any(ch in v for ch in " #'\""):
            v = '"' + v.replace('"', '\\"') + '"'
        lines.append(f"{k}={v}")
    (p["dir"] / ".env").write_text("\n".join(lines) + "\n")
    (p["dir"] / ".env").chmod(0o600)
    return RedirectResponse(f"/project/{name}/env?saved=1", status_code=303)


# ---------------------------------------------------------------------------
# ollama bridge
# ---------------------------------------------------------------------------
@app.get("/ollama/models", response_class=HTMLResponse)
def ollama_models(request: Request, _: str = Depends(require_auth)) -> HTMLResponse:
    try:
        with httpx.Client(timeout=5) as c:
            r = c.get(f"{OLLAMA_URL}/api/tags")
            r.raise_for_status()
            models = r.json().get("models", [])
    except httpx.HTTPError as e:
        models = []
        err = str(e)
    else:
        err = ""
    return templates.TemplateResponse(
        "ollama.html",
        {"request": request, "models": models, "error": err, "ollama_url": OLLAMA_URL},
    )


@app.post("/ollama/pull")
def ollama_pull(model: str = Form(...), _: str = Depends(require_auth)) -> RedirectResponse:
    try:
        with httpx.Client(timeout=None) as c:
            c.post(f"{OLLAMA_URL}/api/pull", json={"model": model, "stream": False})
    except httpx.HTTPError:
        pass
    return RedirectResponse("/ollama/models", status_code=303)


# ---------------------------------------------------------------------------
# router health proxy
# ---------------------------------------------------------------------------
@app.get("/router/health")
def router_health(_: str = Depends(require_auth)) -> dict[str, Any]:
    try:
        with httpx.Client(timeout=3) as c:
            r = c.get(f"{ROUTER_URL}/health")
            r.raise_for_status()
            return r.json()
    except httpx.HTTPError as e:
        return {"status": "unreachable", "error": str(e), "url": ROUTER_URL}
