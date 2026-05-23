import socket
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(title="raspberry-pi-projects: dynamic site starter")


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return """
    <!doctype html>
    <html lang="en"><head><meta charset="utf-8">
    <title>FastAPI on a Pi</title>
    <style>
      body { font-family: system-ui, sans-serif; max-width: 36rem;
             margin: 4rem auto; padding: 0 1rem; line-height: 1.6; }
      code { background: #eee; padding: 0.1rem 0.3rem; border-radius: 4px; }
    </style></head><body>
    <h1>FastAPI is running on your Pi.</h1>
    <p>Try <a href="/api/health">/api/health</a> for JSON.</p>
    <p>Edit <code>app/main.py</code> and rebuild with
       <code>docker compose up -d --build</code>.</p>
    </body></html>
    """


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok", "host": socket.gethostname()}
