"""
Avatar service — port 8002.

MVP1: photo storage + Piper TTS synthesis. The agent (port 8001) calls
`POST /session/{id}/speak` once per sentence and streams the WAV bytes to
the browser via its existing audio pipeline. The browser separately fetches
`/avatars/{id}/photo` as a plain image.

MVP2 will add WebRTC video tracks + 2D mouth animation. The route surface
won't change — only the implementation behind /session/speak.
"""
import uuid
from pathlib import Path

from dotenv import load_dotenv

# Load .env from the project root (absolute path — robust to whatever cwd
# uvicorn / its reloader subprocess decides to use).
_ENV_PATH = Path(__file__).resolve().parents[2] / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response
from pydantic import BaseModel

import tts

import uvicorn

PHOTOS_DIR = Path(__file__).parent / "photos"
PHOTOS_DIR.mkdir(exist_ok=True)

# In-memory registry: avatar_id → { photo_path, voice_id }
_registry: dict[str, dict] = {}


app = FastAPI(title="Avatar Service", version="0.1.0-mvp1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"service": "avatar-service", "status": "running",
            "phase": "MVP1 — photo + edge-tts (Piper substitute on Python 3.13)",
            "default_voice": tts.DEFAULT_VOICE}


@app.get("/health")
def health():
    return {"status": "ok"}


# ── Avatar registration ──────────────────────────────────────────────────────

class RegisterResponse(BaseModel):
    avatar_id: str
    photo_url: str
    voice_id: str


# All avatar-service routes live under `/avatar-svc/` so the gateway can
# fan them out cleanly without ever clashing with agent paths like
# `/session/{id}` (DELETE) or `/admin/avatars/*`.

@app.post("/avatar-svc/photo", response_model=RegisterResponse)
async def register_photo(
    photo: UploadFile = File(...),
    voice_id: str = Form(default="en_US-amy-medium"),
):
    if not (photo.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image uploads are supported")
    photo_bytes = await photo.read()
    if not photo_bytes:
        raise HTTPException(status_code=400, detail="Empty file")

    avatar_id = uuid.uuid4().hex
    ext = ".jpg"
    if photo.filename and "." in photo.filename:
        ext = "." + photo.filename.rsplit(".", 1)[-1].lower()
    photo_path = PHOTOS_DIR / f"{avatar_id}{ext}"
    photo_path.write_bytes(photo_bytes)

    # Edge-tts has no model file to warm; this is a no-op kept for parity
    # with future engines that do need explicit loading.
    try:
        await tts.warm(voice_id)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Voice '{voice_id}' unavailable: {e}")

    _registry[avatar_id] = {"photo_path": str(photo_path), "voice_id": voice_id}
    return RegisterResponse(
        avatar_id=avatar_id,
        photo_url=f"/avatar-svc/{avatar_id}/photo",
        voice_id=voice_id,
    )


@app.get("/avatar-svc/{avatar_id}/photo")
def serve_photo(avatar_id: str):
    rec = _registry.get(avatar_id)
    if not rec:
        # Disk fallback so restarts don't lose photos already uploaded.
        for ext in (".jpg", ".jpeg", ".png", ".webp"):
            p = PHOTOS_DIR / f"{avatar_id}{ext}"
            if p.exists():
                return FileResponse(p)
        raise HTTPException(status_code=404, detail="Photo not found")
    return FileResponse(rec["photo_path"])


# ── Speech ──────────────────────────────────────────────────────────────────

class SpeakRequest(BaseModel):
    text: str
    voice_id: str | None = None


@app.post("/avatar-svc/{avatar_id}/speak")
async def speak(avatar_id: str, req: SpeakRequest):
    """Synthesize one sentence. Returns audio/wav bytes the browser plays
    sequentially through the existing SentenceAudioPlayer. MVP2 swaps this
    for a WebRTC audio + animated video track on the same session id."""
    text = (req.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")
    rec = _registry.get(avatar_id)
    voice_id = req.voice_id or (rec["voice_id"] if rec else None)
    try:
        audio = await tts.synthesize(text, voice_id)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Synthesis failed: {e}")
    return Response(content=audio, media_type="audio/mpeg",
                    headers={"Cache-Control": "no-store"})


@app.delete("/avatar-svc/{avatar_id}")
def unregister(avatar_id: str):
    rec = _registry.pop(avatar_id, None)
    if rec:
        try:
            Path(rec["photo_path"]).unlink(missing_ok=True)
        except Exception:
            pass
    return {"status": "ok", "deleted": rec is not None}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
