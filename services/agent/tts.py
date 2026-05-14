"""
Streaming TTS.

edge-tts is the default — free, CPU-only, supports English / Tamil / Hindi out of
the box, and streams MP3 chunks. The public surface here (`synthesize_sentence`,
`pick_voice`) is intentionally minimal so XTTS-v2 streaming (voice cloning) or
any other engine can be dropped in without touching the WebSocket layer.
"""
import os
import edge_tts

DEFAULT_VOICE = os.getenv("TTS_VOICE", "en-IN-NeerjaNeural")
DEFAULT_RATE  = os.getenv("TTS_RATE", "+0%")

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
    """One sentence in, MP3 bytes out. Concurrent calls are safe."""
    voice = voice or pick_voice(text)
    communicate = edge_tts.Communicate(text, voice, rate=DEFAULT_RATE)
    buf = bytearray()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            buf.extend(chunk["data"])
    return bytes(buf)
