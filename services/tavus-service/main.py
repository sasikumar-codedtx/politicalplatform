"""
tavus-service — port 8005.

Thin proxy in front of the Tavus REST API. Browser hits us at
http://localhost:9000/tavus-svc/* and we forward to tavusapi.com using
the server-side API key (never exposed to the browser).

Phase 1 (current): built-in Tavus LLM with our system prompt. No webhook
needed, no public URL. The Tavus persona handles the conversation logic.

Phase 2 (future): custom LLM mode — Tavus calls our /tavus-svc/webhook
on each user turn, we delegate to agent (Ollama+RAG), reply back. Needs
a public URL (ngrok in dev, deployed gateway in prod). The webhook
endpoint is stubbed below.
"""
import os
from pathlib import Path

from dotenv import load_dotenv

# Load .env from project root with an absolute path — robust to uvicorn
# reloader subprocess cwd.
_ENV_PATH = Path(__file__).resolve().parents[2] / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import tavus_client

import uvicorn


_DOCS = os.getenv("ENABLE_DOCS", "false").strip().lower() in ("1", "true", "yes", "on")

app = FastAPI(
    title="Tavus Service", version="0.1.0",
    docs_url="/docs" if _DOCS else None,
    redoc_url="/redoc" if _DOCS else None,
    openapi_url="/openapi.json" if _DOCS else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# Where we keep the system prompt our Tavus persona uses. Sourced from
# .env so admins can override without restarting the agent. Default is
# the TVK / Vijay character.
DEFAULT_SYSTEM_PROMPT = os.getenv(
    "TAVUS_SYSTEM_PROMPT",
    "You are Vijay, founder of TVK and Chief Minister of Tamil Nadu. "
    "You speak with warmth and conviction in 3-5 sentences. "
    "You stand for social justice, equality, and Tamil welfare. "
    "If the user writes in Tamil, reply in Tamil. Otherwise reply in English."
)
DEFAULT_GREETING = os.getenv(
    "TAVUS_DEFAULT_GREETING",
    "Vanakkam. I'm Vijay. Tell me what's on your mind."
)


@app.get("/")
def root():
    return {
        "service": "tavus-service",
        "status":  "running",
        "phase":   "Tavus built-in LLM (no webhook). Phase 2 = custom LLM via webhook.",
        "api_base": tavus_client.TAVUS_API_BASE,
    }


@app.get("/health")
def health():
    return {"status": "ok"}


# ── Replica & persona listings ──────────────────────────────────────────────

class CreateReplicaRequest(BaseModel):
    train_video_url: str
    replica_name: str
    callback_url: str | None = None


@app.get("/tavus-svc/replicas")
async def replicas():
    try:
        return await tavus_client.list_replicas()
    except tavus_client.TavusError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Tavus list_replicas failed: {e}")


@app.post("/tavus-svc/replicas")
async def create_replica(req: CreateReplicaRequest):
    """Train a new personal replica (face + voice together).

    `train_video_url` must be a publicly reachable HTTPS URL — Tavus
    downloads the video on their end. Local file uploads aren't supported
    here yet; host the clip on S3 / Cloudinary / a public Drive link first."""
    if not req.train_video_url.startswith(("http://", "https://")):
        raise HTTPException(status_code=400, detail="train_video_url must be a public http(s) URL")
    if not req.replica_name.strip():
        raise HTTPException(status_code=400, detail="replica_name is required")
    try:
        return await tavus_client.create_replica(
            train_video_url=req.train_video_url,
            replica_name=req.replica_name.strip(),
            callback_url=req.callback_url,
        )
    except tavus_client.TavusError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Tavus create_replica failed: {e}")


@app.get("/tavus-svc/replicas/{replica_id}")
async def get_replica(replica_id: str):
    """Poll training status. `status` moves pending → training → ready
    (or error). Typically ~30-60 minutes for ready."""
    try:
        return await tavus_client.get_replica(replica_id)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Tavus get_replica failed: {e}")


@app.delete("/tavus-svc/replicas/{replica_id}")
async def delete_replica(replica_id: str):
    await tavus_client.delete_replica(replica_id)
    return {"status": "deleted", "id": replica_id}


@app.get("/tavus-svc/personas")
async def personas():
    try:
        return await tavus_client.list_personas()
    except tavus_client.TavusError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Tavus list_personas failed: {e}")


# ── Conversation lifecycle ──────────────────────────────────────────────────

class StartConversationRequest(BaseModel):
    replica_id: str
    persona_id: str | None = None
    system_prompt: str | None = None
    greeting: str | None = None
    conversation_name: str | None = None


@app.post("/tavus-svc/conversations")
async def start_conversation(req: StartConversationRequest):
    if not req.replica_id.strip():
        raise HTTPException(status_code=400, detail="replica_id is required")
    try:
        result = await tavus_client.create_conversation(
            replica_id=req.replica_id,
            persona_id=req.persona_id,
            conversational_context=req.system_prompt or DEFAULT_SYSTEM_PROMPT,
            custom_greeting=req.greeting or DEFAULT_GREETING,
            conversation_name=req.conversation_name or "Political Platform Chat",
        )
    except tavus_client.TavusError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Tavus create_conversation failed: {e}")
    return result


@app.get("/tavus-svc/conversations/{conv_id}")
async def get_conversation(conv_id: str):
    try:
        return await tavus_client.get_conversation(conv_id)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Tavus get_conversation failed: {e}")


@app.delete("/tavus-svc/conversations/{conv_id}")
async def end_conversation(conv_id: str):
    await tavus_client.end_conversation(conv_id)
    return {"status": "ended", "id": conv_id}


# ── Custom-LLM webhook (Phase 2 — stub for now) ─────────────────────────────

@app.post("/tavus-svc/webhook")
async def llm_webhook(request: Request):
    """Tavus calls this for each user turn when conversations are configured
    with custom_llm_url. We'd forward to agent's /chat and return the reply.

    Stubbed in Phase 1 — Tavus's built-in LLM handles conversations directly.
    Wire this up when you have a public URL (ngrok / Cloudflare Tunnel /
    deployed gateway) and want full Ollama + RAG."""
    body = await request.json()
    raise HTTPException(
        status_code=501,
        detail="Custom-LLM webhook is Phase 2. Currently using Tavus built-in LLM.",
    )


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8005, reload=True)
