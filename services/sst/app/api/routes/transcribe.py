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

# Unicode blocks we can identify from the transcript itself.
_SCRIPT_BLOCKS = {
    "ta": (0x0B80, 0x0BFF),   # Tamil
    "hi": (0x0900, 0x097F),   # Devanagari
}


def _script_of(text: str) -> Optional[str]:
    """Identify the language from the script the transcript is written in.

    Whisper routinely mislabels a short Tamil clip as another Indic language
    (hi/ml/te/kn) while still transcribing it correctly in Tamil script. The
    script is the more reliable signal, so we check it before rejecting.
    """
    letters = [c for c in text if c.isalpha()]
    if not letters:
        return None
    for code, (lo, hi) in _SCRIPT_BLOCKS.items():
        hits = sum(1 for c in letters if lo <= ord(c) <= hi)
        if hits / len(letters) >= 0.30:
            return code
    if sum(1 for c in letters if ord(c) < 128) / len(letters) >= 0.80:
        return "en"
    return None


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

        # Allow-list enforcement — drop the result if the detected language
        # isn't one we've enabled in .env (STT_LANGUAGES). Mobile shows the
        # error so the user knows to switch to a supported language.
        detected = (result.get("language") or "").lower()
        if detected and detected not in settings.SUPPORTED_LANGUAGES:
            # The label is unreliable on short clips — believe the script the
            # transcript actually came back in before turning the user away.
            by_script = _script_of(result["text"])
            if by_script in settings.SUPPORTED_LANGUAGES:
                logger.info(f"[REST-STT] relabelled {detected} → {by_script} (script match)")
                detected = by_script
            else:
                allowed = ", ".join(sorted(settings.SUPPORTED_LANGUAGES))
                logger.info(
                    f"[REST-STT] rejected — detected={detected} script={by_script} "
                    f"not in allow-list [{allowed}]"
                )
                return JSONResponse(status_code=422, content={
                    "text": "",
                    "language": detected,
                    "error": "Sorry, I could not understand that. Please speak in Tamil or English.",
                })

        logger.info(f"[REST-STT] lang={detected or 'auto'} → \"{result['text'][:80]}\"")
        return {
            "text":                 result["text"],
            "language":             detected or lang or "auto",
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
