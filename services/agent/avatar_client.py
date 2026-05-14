"""
Thin async HTTP client to avatar-service (port 8002).

The agent owns conversations and chat history; avatar-service owns photos +
TTS + (later) video. They talk over plain HTTP on localhost so each can
restart independently.
"""
import os
from typing import Optional

import httpx

AVATAR_SERVICE_URL = os.getenv("AVATAR_SERVICE_URL", "http://localhost:8002")


class AvatarServiceError(RuntimeError):
    pass


async def register_photo(photo_bytes: bytes, filename: str, content_type: str,
                          voice_id: str = "en_US-amy-medium") -> dict:
    """Send a face photo to avatar-service, get back an avatar_id we store
    in our `avatars.face_avatar_id` column."""
    async with httpx.AsyncClient(timeout=120.0) as client:
        r = await client.post(
            f"{AVATAR_SERVICE_URL}/avatar-svc/photo",
            files={"photo": (filename or "photo.jpg", photo_bytes, content_type or "image/jpeg")},
            data={"voice_id": voice_id},
        )
        if r.status_code >= 400:
            raise AvatarServiceError(f"register_photo failed: {r.status_code} {r.text[:300]}")
        return r.json()


async def speak(avatar_id: str, text: str, voice_id: Optional[str] = None) -> bytes:
    """Synthesize one sentence on avatar-service. Returns WAV bytes."""
    async with httpx.AsyncClient(timeout=60.0) as client:
        r = await client.post(
            f"{AVATAR_SERVICE_URL}/avatar-svc/{avatar_id}/speak",
            json={"text": text, "voice_id": voice_id},
        )
        if r.status_code >= 400:
            raise AvatarServiceError(f"speak failed: {r.status_code} {r.text[:300]}")
        return r.content


async def unregister(avatar_id: str) -> None:
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            await client.delete(f"{AVATAR_SERVICE_URL}/avatar-svc/{avatar_id}")
        except Exception:
            pass


def photo_url(avatar_id: str) -> str:
    """Public URL the browser uses to <img src="...">.

    Returned path is gateway-relative (`/avatar-svc/...`) so the browser
    can use whatever origin it's already talking to (the 9000 gateway in
    prod, or 8002 direct if you bypass the gateway in tests).
    """
    return f"/avatar-svc/{avatar_id}/photo"
