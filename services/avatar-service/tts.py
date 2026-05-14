"""
Streaming TTS for avatar-service.

Engine: **edge-tts** (Python 3.13 compatible, CPU-only, free, multi-language
incl. Tamil and Hindi). Output is MP3 bytes — the browser decodes natively
via the existing <audio> element pipeline.

Why not Piper as originally planned: `piper-phonemize~=1.1.0` doesn't ship
Python 3.13 wheels yet (as of 2026-05). Functionally edge-tts gives the same
shape (CPU, free, sub-second, multilingual). If you downgrade to Python 3.11
later you can swap the implementation here without touching anything else.
"""
import os
import edge_tts

DEFAULT_VOICE = os.getenv("AVATAR_TTS_VOICE", "en-IN-NeerjaNeural")

# Map the "Piper voice id" strings the admin UI sends (we kept those names
# from the original Piper plan) to the closest equivalent edge-tts voice.
# Anything not in this map is forwarded verbatim — drop the actual edge-tts
# voice id into the field and it'll just work.
_VOICE_ALIAS = {
    "en_US-amy-medium":         "en-US-AriaNeural",
    "en_US-ryan-medium":        "en-US-GuyNeural",
    "en_GB-alan-medium":        "en-GB-RyanNeural",
    "hi_IN-priyamvada-medium":  "hi-IN-SwaraNeural",
}


def _detect_script(text: str) -> str:
    for ch in text:
        c = ord(ch)
        if 0x0B80 <= c <= 0x0BFF: return "tamil"
        if 0x0900 <= c <= 0x097F: return "hindi"
    return "english"


_AUTO_VOICE = {
    "tamil":   "ta-IN-PallaviNeural",
    "hindi":   "hi-IN-SwaraNeural",
    "english": DEFAULT_VOICE,
}


def _resolve_voice(voice_id: str | None, text: str = "") -> str:
    if voice_id:
        return _VOICE_ALIAS.get(voice_id, voice_id)
    return _AUTO_VOICE[_detect_script(text)]


async def synthesize(text: str, voice_id: str | None = None) -> bytes:
    """Returns MP3 bytes. Mime to advertise on the wire: audio/mpeg."""
    voice = _resolve_voice(voice_id, text)
    communicate = edge_tts.Communicate(text, voice)
    buf = bytearray()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            buf.extend(chunk["data"])
    return bytes(buf)


async def warm(voice_id: str | None = None) -> None:
    """No-op for edge-tts (no model loading needed). Kept so the photo
    upload path can call this and behave identically to other engines."""
    return
