"""
gpu-avatar service — port 8003.

Talks the same wire format the real LivePortrait+audio2motion box will speak
once you provision GPU hardware. The pipeline implementation is mocked in
`mock_pipeline.py`; swap that file (or set GPU_PIPELINE=real and import the
real module) when the GPU is ready.

HTTP contract:

    POST   /gpu-svc/sources            multipart photo  →  { source_id }
    GET    /gpu-svc/sources/{id}       JPEG of stored source
    POST   /gpu-svc/sources/{id}/speak multipart audio  →  { task_id }
    GET    /gpu-svc/streams/{task_id}  MJPEG multipart/x-mixed-replace
    DELETE /gpu-svc/sources/{id}                          → cleanup

Frames are produced at 25 fps. Browser embeds the stream URL inside an
`<img>` tag — no JavaScript decoder needed.
"""
import io
import os
import time
import uuid
import wave
from pathlib import Path

import numpy as np
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response

# Load .env from project root (absolute path — survives uvicorn reloader cwd).
_ENV_PATH = Path(__file__).resolve().parents[2] / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)

import mock_pipeline as pipeline
from mjpeg import mjpeg_response

import uvicorn

DATA_DIR = Path(__file__).parent / "data"
SOURCES_DIR = DATA_DIR / "sources"
SOURCES_DIR.mkdir(parents=True, exist_ok=True)

# In-memory task registry: task_id → { source_id, audio_pcm, sample_rate, created_at }
# Tasks live for ~60 s after creation so a single stream consumer can attach.
_tasks: dict[str, dict] = {}
TASK_TTL_SECONDS = 60


def _gc_tasks() -> None:
    now = time.monotonic()
    expired = [t for t, v in _tasks.items() if now - v["created_at"] > TASK_TTL_SECONDS]
    for t in expired:
        _tasks.pop(t, None)


_DOCS = os.getenv("ENABLE_DOCS", "false").strip().lower() in ("1", "true", "yes", "on")

app = FastAPI(
    title="GPU Avatar Service", version="0.1.0-mock",
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


@app.get("/")
def root():
    return {
        "service": "gpu-avatar",
        "status": "running",
        "phase": "MOCK pipeline — swap mock_pipeline.py for real LivePortrait+audio2motion",
        "frame_rate": pipeline.FRAME_RATE,
    }


@app.get("/health")
def health():
    return {"status": "ok"}


# ── Source photo registry ────────────────────────────────────────────────────

@app.post("/gpu-svc/sources")
async def upload_source(photo: UploadFile = File(...)):
    if not (photo.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image uploads are supported")
    photo_bytes = await photo.read()
    if not photo_bytes:
        raise HTTPException(status_code=400, detail="Empty photo")

    source_id = uuid.uuid4().hex
    # Always store as .jpg — pipeline only reads RGB, the wrapper handles format.
    (SOURCES_DIR / f"{source_id}.jpg").write_bytes(photo_bytes)
    return {"source_id": source_id}


@app.get("/gpu-svc/sources/{source_id}")
def get_source(source_id: str):
    p = SOURCES_DIR / f"{source_id}.jpg"
    if not p.exists():
        raise HTTPException(status_code=404, detail="Source not found")
    return Response(content=p.read_bytes(), media_type="image/jpeg")


@app.delete("/gpu-svc/sources/{source_id}")
def delete_source(source_id: str):
    p = SOURCES_DIR / f"{source_id}.jpg"
    if p.exists():
        p.unlink()
    return {"status": "ok"}


# ── Speech tasks ─────────────────────────────────────────────────────────────

@app.post("/gpu-svc/sources/{source_id}/speak")
async def queue_speech(source_id: str, audio: UploadFile = File(...)):
    """Accept audio (wav or raw int16 PCM) and register a render task.
    Returns a task_id the client uses with GET /gpu-svc/streams/{task_id}.
    The MJPEG stream produces ~25 frames per audio second."""
    if not (SOURCES_DIR / f"{source_id}.jpg").exists():
        raise HTTPException(status_code=404, detail="Unknown source_id")
    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio")

    pcm, sample_rate = _decode_audio(audio_bytes, audio.content_type or "")
    if pcm.size == 0:
        raise HTTPException(status_code=400, detail="Audio decoded to zero samples")

    _gc_tasks()
    task_id = uuid.uuid4().hex
    _tasks[task_id] = {
        "source_id":   source_id,
        "audio_pcm":   pcm,
        "sample_rate": sample_rate,
        "created_at":  time.monotonic(),
    }
    return {"task_id": task_id, "frames": int(len(pcm) / sample_rate * pipeline.FRAME_RATE)}


@app.get("/gpu-svc/streams/{task_id}")
def stream_task(task_id: str):
    task = _tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    src = (SOURCES_DIR / f"{task['source_id']}.jpg").read_bytes()
    return mjpeg_response(pipeline.render_frames(
        source_jpeg=src,
        audio_pcm=task["audio_pcm"],
        sample_rate=task["sample_rate"],
    ))


@app.get("/gpu-svc/streams/{task_id}/audio")
def stream_task_audio(task_id: str):
    """Parallel audio side-channel for the task's video stream. Browser plays
    this in an <audio> element alongside the <img src=".../streams/{id}">,
    triggered at the same sentence boundary. When the real GPU pipeline ships,
    audio + video are muxed in a single MPEG-TS stream instead and this
    endpoint becomes unused."""
    task = _tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(task["sample_rate"])
        wf.writeframes(task["audio_pcm"].tobytes())
    return Response(content=buf.getvalue(), media_type="audio/wav",
                    headers={"Cache-Control": "no-store"})


@app.get("/gpu-svc/sources/{source_id}/idle")
def stream_idle(source_id: str):
    """Long-lived MJPEG stream that shows the source photo with idle motion
    until the consumer disconnects. Useful when the browser wants the avatar
    visible between speak() calls."""
    p = SOURCES_DIR / f"{source_id}.jpg"
    if not p.exists():
        raise HTTPException(status_code=404, detail="Source not found")
    return mjpeg_response(pipeline.render_idle_loop(p.read_bytes()))


# ── Audio decoding ───────────────────────────────────────────────────────────

def _decode_audio(payload: bytes, content_type: str) -> tuple[np.ndarray, int]:
    """Returns (int16 PCM samples, sample_rate). Supports WAV; falls back to
    raw int16 mono @ 22050 Hz when the content type doesn't say otherwise."""
    ct = (content_type or "").lower()
    if ct in ("audio/wav", "audio/wave", "audio/x-wav") or payload[:4] == b"RIFF":
        with wave.open(io.BytesIO(payload), "rb") as wf:
            sr = wf.getframerate()
            frames = wf.readframes(wf.getnframes())
            pcm = np.frombuffer(frames, dtype=np.int16)
            if wf.getnchannels() == 2:
                pcm = pcm.reshape(-1, 2).mean(axis=1).astype(np.int16)
            return pcm, sr
    # MP3 / OGG / unknown — fall back: treat as raw int16. Works for edge-tts MP3
    # only as an amplitude proxy; the real pipeline should decode properly via
    # PyAV or librosa. The mock cares only about amplitude, so this is fine.
    pcm = np.frombuffer(payload, dtype=np.int16, count=len(payload) // 2)
    return pcm.copy(), 22050


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8003, reload=True)
