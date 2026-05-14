"""
REST transcription endpoint — file-based (non-live).

POST /asr       — compatible with existing backend core/stt.py
POST /transcribe — alias with cleaner name

Both accept a multipart audio_file and optional ?language=sw|en.
They use the same faster-whisper model pool as the WebSocket endpoint.
"""

import asyncio
import logging
import os
import uuid
from typing import Optional

from fastapi import APIRouter, File, Query, UploadFile
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.lifespan import executor
from app.services.load_monitor import get_load_level
from app.services.stt_engine import transcribe_file

router = APIRouter(tags=["transcribe"])
logger = logging.getLogger("stt.rest")

_ALLOWED_AUDIO = {
    "audio/wav", "audio/wave", "audio/x-wav",
    "audio/mpeg", "audio/mp3",
    "audio/ogg", "audio/webm",
    "audio/mp4", "audio/m4a", "audio/x-m4a",
    "audio/flac", "audio/x-flac",
    "video/webm",                 # Chrome MediaRecorder outputs video/webm for audio-only
    "application/octet-stream",   # Flutter http.MultipartFile.fromPath default
    "",                           # missing Content-Type — accept; we sniff by extension below
}

_AUDIO_EXTS = {".wav", ".mp3", ".m4a", ".mp4", ".ogg", ".webm", ".flac", ".aac"}

_MAX_AUDIO_BYTES = 10 * 1024 * 1024   # 10 MB


async def _infer(file_path: str, lang: Optional[str], initial_prompt: str = "") -> dict:
    level = get_load_level()
    if level == "overload":
        level = "shed"
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(executor, transcribe_file, file_path, lang, level, initial_prompt)


@router.post("/asr")
@router.post("/transcribe")
async def transcribe_audio(
    audio_file:     UploadFile = File(...),
    language:       Optional[str] = Query(None),
    task:           Optional[str] = Query("transcribe"),  # compat param — ignored
    initial_prompt: Optional[str] = Query(None),
):
    """
    Transcribe an uploaded audio file.

    Returns:
        { text, language, language_probability }
    or on error:
        { text: "", error: "..." }
    """
    # ── Content-type check ────────────────────────────────────────────────────
    # Some clients (Flutter http.MultipartFile.fromPath) upload audio as
    # application/octet-stream. We accept that AND also accept missing
    # Content-Type — instead we sniff the filename extension as the source
    # of truth. faster-whisper figures the actual codec from file headers.
    ct = (audio_file.content_type or "").split(";")[0].strip().lower()
    ext = os.path.splitext(audio_file.filename or "")[1].lower()
    if ct not in _ALLOWED_AUDIO and ext not in _AUDIO_EXTS:
        logger.warning(f"[REST-STT] Rejected content type={ct!r} ext={ext!r}")
        return JSONResponse(
            status_code=400,
            content={"text": "", "error": f"Unsupported audio type: {ct or 'unknown'} (filename: {audio_file.filename})"},
        )

    # ── Read + size check ─────────────────────────────────────────────────────
    audio_bytes = await audio_file.read()
    if len(audio_bytes) > _MAX_AUDIO_BYTES:
        return JSONResponse(status_code=413, content={"text": "", "error": "Audio too large (max 10 MB)"})
    if len(audio_bytes) < 100:
        return JSONResponse(status_code=400, content={"text": "", "error": "Audio is empty or too short"})

    # ── Language ──────────────────────────────────────────────────────────────
    # If the caller didn't specify a language (or passes "auto"), pass None
    # down so faster-whisper auto-detects from the first speech segment. This
    # is what lets Tamil / Hindi / English speakers all work without the mobile
    # having to know which language was spoken.
    lang: Optional[str] = None
    if language:
        candidate = language.strip().lower()
        if candidate and candidate != "auto":
            # Allow anything; faster-whisper supports 99 languages. We use
            # SUPPORTED_LANGUAGES only to pick a model variant — see stt_engine.
            lang = candidate

    # ── Save temp file ────────────────────────────────────────────────────────
    ext = os.path.splitext(audio_file.filename or "")[1].lower() or ".webm"
    tmp = f"_stt_{uuid.uuid4().hex}{ext}"

    try:
        with open(tmp, "wb") as f:
            f.write(audio_bytes)

        logger.info(f"[REST-STT] {len(audio_bytes)//1024} KB | lang={lang or 'auto'}")
        result = await _infer(tmp, lang, initial_prompt or "")

        if not result.get("text"):
            return {
                "text": "",
                "language": result.get("language") or lang or "auto",
                "language_probability": 0.0,
                "error": "No speech detected in audio.",
            }

        logger.info(f"[REST-STT] lang={result.get('language')} → \"{result['text'][:80]}\"")
        return {
            "text":                 result["text"],
            "language":             result.get("language") or lang or "auto",
            "language_probability": result.get("language_probability", 1.0),
        }

    except Exception as e:
        logger.error(f"[REST-STT] Failed: {e}")
        return JSONResponse(status_code=500, content={
            "text": "",
            "error": "Transcription failed. Please try again.",
        })

    finally:
        try:
            os.remove(tmp)
        except OSError:
            pass
