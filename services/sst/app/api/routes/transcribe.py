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
    "video/webm",   # Chrome MediaRecorder outputs video/webm for audio-only
}

_MAX_AUDIO_BYTES = 10 * 1024 * 1024   # 10 MB


async def _infer(file_path: str, lang: str, initial_prompt: str = "") -> dict:
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
    ct = (audio_file.content_type or "").split(";")[0].strip().lower()
    if ct and ct not in _ALLOWED_AUDIO:
        logger.warning(f"[REST-STT] Rejected content type: {ct}")
        return JSONResponse(status_code=400, content={"text": "", "error": f"Unsupported audio type: {ct}"})

    # ── Read + size check ─────────────────────────────────────────────────────
    audio_bytes = await audio_file.read()
    if len(audio_bytes) > _MAX_AUDIO_BYTES:
        return JSONResponse(status_code=413, content={"text": "", "error": "Audio too large (max 10 MB)"})
    if len(audio_bytes) < 100:
        return JSONResponse(status_code=400, content={"text": "", "error": "Audio is empty or too short"})

    # ── Language ──────────────────────────────────────────────────────────────
    lang = "en"
    if language:
        candidate = language.strip().lower()
        if candidate in settings.SUPPORTED_LANGUAGES:
            lang = candidate

    # ── Save temp file ────────────────────────────────────────────────────────
    ext = os.path.splitext(audio_file.filename or "")[1].lower() or ".webm"
    tmp = f"_stt_{uuid.uuid4().hex}{ext}"

    try:
        with open(tmp, "wb") as f:
            f.write(audio_bytes)

        logger.info(f"[REST-STT] {len(audio_bytes)//1024} KB | lang={lang}")
        result = await _infer(tmp, lang, initial_prompt or "")

        if not result.get("text"):
            return {
                "text": "",
                "language": lang,
                "language_probability": 0.0,
                "error": "No speech detected in audio.",
            }

        logger.info(f"[REST-STT] → \"{result['text'][:80]}\"")
        return {
            "text":                 result["text"],
            "language":             result.get("language", lang),
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
