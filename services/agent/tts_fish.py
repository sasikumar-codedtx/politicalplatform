"""
Voice-cloned TTS via Fish Audio (cloud API at api.fish.audio).

Two surfaces, both async:
  synthesize_cloned(text)         → bytes (full MP3, for /tts disk cache writes)
  stream_cloned(text)             → async iterator of MP3 chunks (for WS first-audio)

`stream_cloned` uses Fish's chunked-transfer streaming endpoint — first bytes
arrive in ~250-400ms instead of waiting 1-3s for the full sentence. The WS
layer can start sending audio to mobile the moment the first chunk lands.

A module-level httpx.AsyncClient is reused across calls so we don't pay the
~150ms TCP+TLS handshake to api.fish.audio on every sentence.
"""
import os
from typing import AsyncIterator

import httpx

FISH_URL = os.getenv("FISH_AUDIO_URL", "https://api.fish.audio").rstrip("/")
FISH_KEY = os.getenv("FISH_AUDIO_API_KEY", "")
FISH_VOICE = os.getenv("FISH_AUDIO_VOICE_ID", "")


def _headers() -> dict[str, str]:
    h: dict[str, str] = {"Content-Type": "application/json"}
    if FISH_KEY:
        h["Authorization"] = f"Bearer {FISH_KEY}"
    return h


_client: httpx.AsyncClient | None = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None:
        _client = httpx.AsyncClient(
            timeout=httpx.Timeout(30.0, connect=5.0),
            http2=False,
            limits=httpx.Limits(max_keepalive_connections=20, keepalive_expiry=60.0),
        )
    return _client


def _payload(text: str) -> dict:
    if not FISH_VOICE:
        raise RuntimeError(
            "FISH_AUDIO_VOICE_ID is not set. "
            "Clone a voice on fish.audio first, then add the model ID to .env."
        )
    return {
        "text": text,
        "reference_id": FISH_VOICE,
        "format": "mp3",
        "mp3_bitrate": 128,
        "latency": "balanced",
    }


async def synthesize_cloned(text: str) -> bytes:
    """One sentence in, full MP3 bytes out. Concurrent-safe."""
    client = _get_client()
    resp = await client.post(
        f"{FISH_URL}/v1/tts",
        json=_payload(text),
        headers=_headers(),
    )
    if resp.status_code != 200:
        raise RuntimeError(
            f"Fish TTS failed: {resp.status_code} {resp.text[:300]}"
        )
    return resp.content


async def stream_cloned(text: str) -> AsyncIterator[bytes]:
    """Stream MP3 chunks as Fish produces them. First chunk in ~300ms."""
    client = _get_client()
    async with client.stream(
        "POST",
        f"{FISH_URL}/v1/tts",
        json=_payload(text),
        headers=_headers(),
    ) as resp:
        if resp.status_code != 200:
            body = await resp.aread()
            raise RuntimeError(
                f"Fish TTS stream failed: {resp.status_code} {body[:300]!r}"
            )
        async for chunk in resp.aiter_bytes():
            if chunk:
                yield chunk
