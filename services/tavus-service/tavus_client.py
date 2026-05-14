"""
Async client for the Tavus REST API (https://tavusapi.com).

Auth: x-api-key header on every request. TAVUS_API_KEY env required.

Endpoints we use:
  GET  /v2/replicas                 list stock + custom replicas
  GET  /v2/personas                 list personas
  POST /v2/conversations            start a Conversational Video Interface
                                    session (returns Daily.co room URL)
  POST /v2/conversations/{id}/end   close the room

Tavus docs: https://docs.tavus.io
"""
import os
from typing import Any

import httpx

TAVUS_API_BASE = os.getenv("TAVUS_API_BASE", "https://tavusapi.com").rstrip("/")


class TavusError(RuntimeError):
    pass


def _api_key() -> str:
    key = os.getenv("TAVUS_API_KEY", "").strip()
    if not key:
        raise TavusError(
            "TAVUS_API_KEY is not set. Sign up at https://tavus.io → "
            "Developer → API keys, then add TAVUS_API_KEY=... to .env."
        )
    return key


def _headers() -> dict[str, str]:
    return {"x-api-key": _api_key(), "Content-Type": "application/json"}


async def list_replicas() -> dict[str, Any]:
    async with httpx.AsyncClient(timeout=30.0) as c:
        r = await c.get(f"{TAVUS_API_BASE}/v2/replicas", headers=_headers())
        r.raise_for_status()
        return r.json()


async def create_replica(train_video_url: str,
                         replica_name: str,
                         callback_url: str | None = None) -> dict[str, Any]:
    """Kick off training for a new personal replica. Trains face + voice
    together from one video — there is no voice-only path in CVI.

    `train_video_url` must be a publicly reachable HTTPS URL Tavus can
    download (S3, Cloudinary, public Drive, etc.). Returns immediately;
    poll get_replica(id) until `status == 'ready'` (~30-60 min)."""
    body: dict[str, Any] = {
        "train_video_url": train_video_url,
        "replica_name":    replica_name,
    }
    if callback_url:
        body["callback_url"] = callback_url
    async with httpx.AsyncClient(timeout=60.0) as c:
        r = await c.post(
            f"{TAVUS_API_BASE}/v2/replicas",
            headers=_headers(),
            json=body,
        )
        if r.status_code >= 400:
            raise TavusError(f"Tavus rejected replica: {r.status_code} {r.text[:400]}")
        return r.json()


async def get_replica(replica_id: str) -> dict[str, Any]:
    async with httpx.AsyncClient(timeout=15.0) as c:
        r = await c.get(
            f"{TAVUS_API_BASE}/v2/replicas/{replica_id}",
            headers=_headers(),
        )
        r.raise_for_status()
        return r.json()


async def delete_replica(replica_id: str) -> None:
    async with httpx.AsyncClient(timeout=15.0) as c:
        try:
            await c.delete(
                f"{TAVUS_API_BASE}/v2/replicas/{replica_id}",
                headers=_headers(),
            )
        except Exception:
            pass


async def list_personas() -> dict[str, Any]:
    async with httpx.AsyncClient(timeout=30.0) as c:
        r = await c.get(f"{TAVUS_API_BASE}/v2/personas", headers=_headers())
        r.raise_for_status()
        return r.json()


async def create_conversation(replica_id: str,
                              persona_id: str | None = None,
                              conversational_context: str | None = None,
                              custom_greeting: str | None = None,
                              conversation_name: str = "Political Platform Chat") -> dict[str, Any]:
    """Open a CVI session. Returns a payload that includes `conversation_url`
    (a Daily.co room) and `conversation_id`. The browser embeds the URL in
    an <iframe> for two-way video chat.

    Use `conversational_context` to pass the system prompt — that becomes
    the persona's instructions for this conversation when no persona_id is
    given. With persona_id set, the persona's built-in prompt is used and
    context is appended as extra context for the turn."""
    body: dict[str, Any] = {
        "replica_id": replica_id,
        "conversation_name": conversation_name,
    }
    if persona_id:
        body["persona_id"] = persona_id
    if conversational_context:
        body["conversational_context"] = conversational_context
    if custom_greeting:
        body["custom_greeting"] = custom_greeting

    async with httpx.AsyncClient(timeout=60.0) as c:
        r = await c.post(
            f"{TAVUS_API_BASE}/v2/conversations",
            headers=_headers(),
            json=body,
        )
        if r.status_code >= 400:
            raise TavusError(f"Tavus rejected conversation: {r.status_code} {r.text[:400]}")
        return r.json()


async def end_conversation(conversation_id: str) -> None:
    async with httpx.AsyncClient(timeout=15.0) as c:
        try:
            await c.post(
                f"{TAVUS_API_BASE}/v2/conversations/{conversation_id}/end",
                headers=_headers(),
            )
        except Exception:
            pass


async def get_conversation(conversation_id: str) -> dict[str, Any]:
    async with httpx.AsyncClient(timeout=15.0) as c:
        r = await c.get(
            f"{TAVUS_API_BASE}/v2/conversations/{conversation_id}",
            headers=_headers(),
        )
        r.raise_for_status()
        return r.json()
