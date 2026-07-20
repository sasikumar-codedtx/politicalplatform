"""
Streaming TTS.

edge-tts is the default — free, CPU-only, supports English / Tamil / Hindi out of
the box, and streams MP3 chunks. The public surface here (`synthesize_sentence`,
`pick_voice`) is intentionally minimal so alternative engines can be dropped in
without touching the WebSocket layer.

Set TTS_ENGINE=fish in .env to use Fish Audio voice cloning (Vijay's voice).
Set TTS_ENGINE=edge (default) for generic Microsoft Neural voices.
"""
import os
from typing import AsyncIterator
import edge_tts
from pronunciation import apply_pronunciation

TTS_ENGINE    = os.getenv("TTS_ENGINE", "edge")
DEFAULT_VOICE = os.getenv("TTS_VOICE", "en-IN-NeerjaNeural")
DEFAULT_RATE  = os.getenv("TTS_RATE", "+0%")
TTS_FLAVOR    = os.getenv("TTS_FLAVOR", "tn-tvk")

_VOICE_BY_SCRIPT = {
    "tamil":   os.getenv("TTS_VOICE_TAMIL",   "ta-IN-PallaviNeural"),
    "hindi":   os.getenv("TTS_VOICE_HINDI",   "hi-IN-SwaraNeural"),
    "english": DEFAULT_VOICE,
}


def _detect_script(text: str) -> str:
    for ch in text:
        c = ord(ch)
        if 0x0B80 <= c <= 0x0BFF:
            return "tamil"
        if 0x0900 <= c <= 0x097F:
            return "hindi"
    return "english"


def pick_voice(text: str) -> str:
    return _VOICE_BY_SCRIPT[_detect_script(text)]


async def synthesize_sentence(text: str, voice: str | None = None) -> bytes:
    """One sentence in, MP3 bytes out. Concurrent calls are safe.

    Pronunciation fixes (see pronunciation.py) are applied to [text] before
    the engine sees it — display/db text is unchanged. The upstream disk
    cache is keyed on the ORIGINAL text so cache invariants stay intact.
    """
    spoken = apply_pronunciation(text, flavor_id=TTS_FLAVOR)

    if TTS_ENGINE == "fish":
        from tts_fish import synthesize_cloned
        return await synthesize_cloned(spoken)

    voice = voice or pick_voice(spoken)
    communicate = edge_tts.Communicate(spoken, voice, rate=DEFAULT_RATE)
    buf = bytearray()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            buf.extend(chunk["data"])
    return bytes(buf)


async def stream_sentence(text: str, voice: str | None = None) -> AsyncIterator[bytes]:
    """Yield MP3 chunks as the engine produces them. First chunk in ~300ms
    on Fish, ~200ms on edge-tts. Caller is responsible for joining chunks
    if it needs the full payload for caching."""
    spoken = apply_pronunciation(text, flavor_id=TTS_FLAVOR)

    if TTS_ENGINE == "fish":
        from tts_fish import stream_cloned
        async for chunk in stream_cloned(spoken):
            yield chunk
        return

    voice = voice or pick_voice(spoken)
    communicate = edge_tts.Communicate(spoken, voice, rate=DEFAULT_RATE)
    async for chunk in communicate.stream():
        if chunk["type"] == "audio" and chunk["data"]:
            yield chunk["data"]
