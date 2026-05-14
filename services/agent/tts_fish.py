"""
Voice-cloned TTS via Fish Audio (cloud API at api.fish.audio).

Drop-in alongside edge-tts. Same async signature:
  synthesize_cloned(text) → MP3 bytes

The cloned voice is created once on fish.audio by uploading a clean
reference audio clip of the target speaker. Every TTS call uses the
resulting reference_id to synthesise new speech in that voice.

Env vars (set in .env):
  FISH_AUDIO_URL      — API base URL (default: https://api.fish.audio)
  FISH_AUDIO_API_KEY  — API key from fish.audio dashboard
  FISH_AUDIO_VOICE_ID — reference_id of the cloned voice model
"""
import os

import httpx

FISH_URL = os.getenv("FISH_AUDIO_URL", "https://api.fish.audio").rstrip("/")
FISH_KEY = os.getenv("FISH_AUDIO_API_KEY", "")
FISH_VOICE = os.getenv("FISH_AUDIO_VOICE_ID", "")


def _headers() -> dict[str, str]:
    h: dict[str, str] = {"Content-Type": "application/json"}
    if FISH_KEY:
        h["Authorization"] = f"Bearer {FISH_KEY}"
    return h


async def synthesize_cloned(text: str) -> bytes:
    """One sentence in, MP3 bytes out. Concurrent-safe (no shared state)."""
    if not FISH_VOICE:
        raise RuntimeError(
            "FISH_AUDIO_VOICE_ID is not set. "
            "Clone a voice on fish.audio first, then add the model ID to .env."
        )

    payload = {
        "text": text,
        "reference_id": FISH_VOICE,
        "format": "mp3",
        "mp3_bitrate": 128,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(
            f"{FISH_URL}/v1/tts",
            json=payload,
            headers=_headers(),
        )
        if resp.status_code != 200:
            raise RuntimeError(
                f"Fish TTS failed: {resp.status_code} {resp.text[:300]}"
            )
        return resp.content
