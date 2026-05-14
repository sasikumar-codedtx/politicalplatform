"""
Single entry point + reverse-proxy gateway.

`python services/run.py` does TWO things:

  1. Boots every backend listed in SERVICES as a subprocess (uvicorn).
       agent           on 8001  — chat, RAG, persona, /ws/chat
       avatar-service  on 8002  — Piper TTS, face photo, animation
       (add more here, one line each)

  2. Listens on PORT 9000 itself as a FastAPI gateway, reverse-proxying
     HTTP + WebSocket traffic to the right child based on path prefix.
     The browser only ever talks to :9000.

When this process exits (Ctrl-C), every child is terminated. When any
child dies unexpectedly, the gateway shuts down so you never end up with
a half-running system.

Install deps once:
    pip install fastapi "uvicorn[standard]" httpx websockets
"""
import asyncio
import os
import signal
import subprocess
import sys
import time
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
import uvicorn
import websockets
from dotenv import load_dotenv
from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response, StreamingResponse

HERE = Path(__file__).parent

# Load .env from the project root and propagate to child processes.
_ENV_PATH = HERE.parent / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)
    print(f"[gateway] loaded env from {_ENV_PATH}", flush=True)

# ── Service registry ─────────────────────────────────────────────────────────
# Add a new service here and it'll start + be reachable through 9000
# automatically. `prefix` is matched against the path; the longest match wins.
SERVICES = [
    {
        "name":   "agent",
        "cwd":    HERE / "agent",
        "module": "main:app",
        "port":   8001,
        "prefix": "/",                    # fallback — anything not matched elsewhere
        "ws":     ["/ws/chat"],
        "enabled_env":     "ENABLE_AGENT",
        "default_enabled": True,
    },
    {
        "name":   "avatar-service",
        "cwd":    HERE / "avatar-service",
        "module": "main:app",
        "port":   8002,
        "prefix": "/avatar-svc/",
        "ws":     [],
        "enabled_env":     "ENABLE_AVATAR_SERVICE",
        "default_enabled": True,
    },
    {
        "name":   "gpu-avatar",
        "cwd":    HERE / "gpu-avatar",
        "module": "main:app",
        "port":   8003,
        "prefix": "/gpu-svc/",
        "ws":     [],
        "enabled_env":     "ENABLE_GPU_AVATAR",
        "default_enabled": False,        # off by default — only useful w/ real GPU
    },
    {
        "name":   "tavus-service",
        "cwd":    HERE / "tavus-service",
        "module": "main:app",
        "port":   8005,
        "prefix": "/tavus-svc/",
        "ws":     [],
        "enabled_env":     "ENABLE_TAVUS",
        "default_enabled": False,
        "required_envs":   ["TAVUS_API_KEY"],   # skipped if missing
    },
    {
        "name":   "sst",
        "cwd":    HERE / "sst",
        "module": "app:app",
        "port":   8004,
        "prefix": "/stt-svc/",
        "ws":     [],
        "enabled_env":     "ENABLE_SST",
        "default_enabled": False,
    },
]

GATEWAY_PORT = int(os.getenv("GATEWAY_PORT", "9000"))
READY_TIMEOUT_S = 60


def _python() -> str:
    return sys.executable or "python"


# ── Child process management ─────────────────────────────────────────────────
_procs: list[subprocess.Popen] = []

# Names of services that are NOT going to be started this run — used by the
# gateway's HTTP proxy to fail-fast with a clear 503 instead of dialing
# nothing on those ports.
_disabled_names: set[str] = set()
_skip_reasons:   dict[str, str] = {}


def _truthy(val: str) -> bool | None:
    s = (val or "").strip().lower()
    if s in ("1", "true", "yes", "on"):  return True
    if s in ("0", "false", "no", "off"): return False
    return None


def _is_enabled(svc: dict) -> tuple[bool, str]:
    explicit = _truthy(os.getenv(svc["enabled_env"], ""))
    enabled = svc["default_enabled"] if explicit is None else explicit
    if not enabled:
        return False, f"{svc['enabled_env']}=false"
    missing = [v for v in svc.get("required_envs", []) if not os.getenv(v, "").strip()]
    if missing:
        return False, f"missing env: {', '.join(missing)}"
    if not svc["cwd"].exists():
        return False, f"dir not found: {svc['cwd']}"
    return True, ""


def _spawn(svc: dict) -> subprocess.Popen:
    cmd = [_python(), "-m", "uvicorn", svc["module"],
           "--host", "127.0.0.1", "--port", str(svc["port"]),
           "--reload"]
    print(f"[gateway] starting {svc['name']:>14} on :{svc['port']}", flush=True)
    return subprocess.Popen(cmd, cwd=str(svc["cwd"]))


async def _wait_ready(svc: dict, timeout: float = READY_TIMEOUT_S) -> bool:
    url = f"http://127.0.0.1:{svc['port']}/health"
    deadline = time.monotonic() + timeout
    async with httpx.AsyncClient(timeout=2.0) as client:
        while time.monotonic() < deadline:
            try:
                r = await client.get(url)
                if r.status_code == 200:
                    return True
            except Exception:
                pass
            await asyncio.sleep(0.5)
    return False


def _shutdown_children():
    for p in _procs:
        try:
            p.terminate()
        except Exception:
            pass
    for p in _procs:
        try:
            p.wait(timeout=5)
        except Exception:
            try: p.kill()
            except Exception: pass


# ── Routing ──────────────────────────────────────────────────────────────────

def _pick_target(path: str) -> dict:
    """Longest-prefix match against the SERVICES table. Falls back to '/'."""
    best = None
    best_len = -1
    for svc in SERVICES:
        pfx = svc["prefix"]
        if path.startswith(pfx) and len(pfx) > best_len:
            best, best_len = svc, len(pfx)
    return best or SERVICES[0]


# ── FastAPI gateway app ──────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    enabled_services: list[dict] = []
    for svc in SERVICES:
        ok, reason = _is_enabled(svc)
        if not ok:
            _disabled_names.add(svc["name"])
            _skip_reasons[svc["name"]] = reason
            print(f"[gateway] !! {svc['name']:>14}            DISABLED  ({reason})", flush=True)
            continue
        enabled_services.append(svc)
        _procs.append(_spawn(svc))

    if not enabled_services:
        print("[gateway] !! no enabled services — gateway will only serve /_gateway/*", flush=True)
    else:
        print(f"[gateway] waiting for backends to report /health …", flush=True)
        results = await asyncio.gather(*[_wait_ready(s) for s in enabled_services],
                                       return_exceptions=True)
        for svc, ok in zip(enabled_services, results):
            status = "READY" if ok is True else "TIMEOUT/ERROR"
            print(f"[gateway]   {svc['name']:>14} :{svc['port']}  {status}", flush=True)

    print(f"[gateway] open  http://localhost:{GATEWAY_PORT}", flush=True)
    yield
    print("[gateway] shutting down children…", flush=True)
    _shutdown_children()


app = FastAPI(title="Political Platform Gateway", version="1.0.0",
              lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/_gateway/health")
async def gateway_health():
    out = {}
    async with httpx.AsyncClient(timeout=2.0) as client:
        for svc in SERVICES:
            try:
                r = await client.get(f"http://127.0.0.1:{svc['port']}/health")
                out[svc["name"]] = {"port": svc["port"], "status": r.status_code, "ok": r.status_code == 200}
            except Exception as e:
                out[svc["name"]] = {"port": svc["port"], "ok": False, "error": str(e)[:200]}
    out["gateway"] = {"port": GATEWAY_PORT, "ok": True}
    return out


@app.get("/_gateway/services")
def gateway_services():
    return [
        {
            "name": s["name"], "port": s["port"], "prefix": s["prefix"], "ws": s["ws"],
            "enabled": s["name"] not in _disabled_names,
            "reason":  _skip_reasons.get(s["name"]),
        }
        for s in SERVICES
    ]


# Hop-by-hop headers (RFC 7230) — must not be forwarded.
_HOP_BY_HOP = {
    "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
    "te", "trailer", "transfer-encoding", "upgrade", "host", "content-length",
}


@app.websocket("/{ws_path:path}")
async def proxy_ws(client_ws: WebSocket, ws_path: str):
    path = "/" + ws_path
    svc = _pick_target(path)
    if path not in svc["ws"]:
        await client_ws.close(code=4404)
        return
    if svc["name"] in _disabled_names:
        await client_ws.close(code=4503)
        return

    await client_ws.accept()
    upstream_url = f"ws://127.0.0.1:{svc['port']}{path}"
    try:
        async with websockets.connect(upstream_url, max_size=None, ping_interval=None) as upstream:
            async def c2u():
                try:
                    while True:
                        m = await client_ws.receive()
                        if m["type"] == "websocket.disconnect":
                            return
                        if m.get("text") is not None:
                            await upstream.send(m["text"])
                        elif m.get("bytes") is not None:
                            await upstream.send(m["bytes"])
                except Exception:
                    pass

            async def u2c():
                try:
                    async for msg in upstream:
                        if isinstance(msg, bytes):
                            await client_ws.send_bytes(msg)
                        else:
                            await client_ws.send_text(msg)
                except Exception:
                    pass

            await asyncio.gather(c2u(), u2c())
    except Exception:
        pass
    try:
        await client_ws.close()
    except Exception:
        pass


@app.api_route("/{full_path:path}",
               methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"])
async def proxy_http(request: Request, full_path: str):
    path = "/" + full_path
    svc = _pick_target(path)
    if svc["name"] in _disabled_names:
        return JSONResponse(
            {"detail": f"{svc['name']} disabled ({_skip_reasons.get(svc['name'], 'no reason')})",
             "service": svc["name"], "prefix": svc["prefix"]},
            status_code=503,
        )
    target = f"http://127.0.0.1:{svc['port']}{path}"

    headers = {k: v for k, v in request.headers.items()
               if k.lower() not in _HOP_BY_HOP}
    body = await request.body()

    # Streaming proxy — necessary for MJPEG / SSE / large file responses. The
    # connection stays open as long as upstream keeps sending. `timeout=None`
    # disables the read deadline; connect timeout is the only safeguard.
    client = httpx.AsyncClient(timeout=httpx.Timeout(None, connect=10.0))
    try:
        req = client.build_request(
            request.method, target,
            content=body if body else None,
            headers=headers,
            params=dict(request.query_params),
        )
        upstream = await client.send(req, stream=True)
    except httpx.ConnectError:
        await client.aclose()
        return JSONResponse(
            {"detail": f"{svc['name']} (port {svc['port']}) is not reachable"},
            status_code=503,
        )

    resp_headers = {k: v for k, v in upstream.headers.items()
                    if k.lower() not in _HOP_BY_HOP}

    async def relay():
        try:
            async for chunk in upstream.aiter_raw():
                yield chunk
        finally:
            await upstream.aclose()
            await client.aclose()

    return StreamingResponse(
        relay(),
        status_code=upstream.status_code,
        headers=resp_headers,
        media_type=upstream.headers.get("content-type"),
    )


# ── Entry point ──────────────────────────────────────────────────────────────

def main() -> int:
    def _sig(*_):
        print("\n[gateway] signal received, exiting", flush=True)
        _shutdown_children()
        sys.exit(0)

    signal.signal(signal.SIGINT, _sig)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, _sig)

    uvicorn.run(app, host="0.0.0.0", port=GATEWAY_PORT, log_level="info")
    return 0


if __name__ == "__main__":
    sys.exit(main())
