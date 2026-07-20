"""
Async Ollama streaming + sentence buffering.

Emits an event stream:
  {"type": "token",    "text": "Hel"}         every token
  {"type": "sentence", "text": "Hello there"} every sentence boundary
  {"type": "done",     "text": "<full>"}      when the model finishes

The first sentence flushes early (at the first comma / clause boundary) so the
TTS layer can start synthesising audio while later tokens are still streaming.
This is the trick that gets first-audio latency under ~1 second.
"""
import json
import os
import re
from typing import AsyncIterator

import httpx

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL  = os.getenv("LLM_MODEL", "gpt-oss:20b-cloud")

# See agent.py for the rationale — keep the model resident, skip discarded
# reasoning tokens (first content token arrives immediately), cap length.
def _keep_alive():
    # int (seconds; -1 = never unload) or duration string like "24h". A bare
    # "-1" STRING is rejected by Ollama ("missing unit"), so coerce numerics.
    v = os.getenv("OLLAMA_KEEP_ALIVE", "-1")
    try:
        return int(v)
    except ValueError:
        return v


OLLAMA_KEEP_ALIVE = _keep_alive()
LLM_THINK  = os.getenv("LLM_THINK", "false").lower() in ("1", "true", "yes", "on")
LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "512"))

# Sentence terminators across scripts (`.` `!` `?` `।` ellipsis)
_SENTENCE_END = re.compile(r"([.!?।]+|\.{3})(\s+|$)")

# First-sentence early flush: comma / semicolon / "but" / "so" etc.
_EARLY_FLUSH  = re.compile(r"([,;:](?=\s))")
_MIN_FIRST_CHARS = 12


# Module-level pooled client — one TCP+TLS handshake instead of per-request.
# HTTP/2 keepalive shaves ~150ms off every turn against Ollama Cloud.
_client: httpx.AsyncClient | None = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None:
        # HTTP/1.1 only — h2 frames can coalesce small NDJSON tokens from
        # Ollama and make the WS look "batched" on the mobile side.
        _client = httpx.AsyncClient(
            timeout=httpx.Timeout(120.0, connect=10.0),
            http2=False,
            limits=httpx.Limits(max_keepalive_connections=10, keepalive_expiry=120.0),
        )
    return _client


async def warmup() -> None:
    """Load the model and open the pooled connection before the first user.

    Without this the first chat of the day pays model load + TCP/TLS setup
    while someone is watching the typing dots. Failures are ignored — a cold
    first turn is worse than a warm one, but it is not an error.
    """
    try:
        client = _get_client()
        await client.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": LLM_MODEL,
                "messages": [{"role": "user", "content": "hi"}],
                "stream": False,
                "think": False,
                "keep_alive": OLLAMA_KEEP_ALIVE,
                "options": {"num_predict": 1},
            },
            timeout=httpx.Timeout(180.0, connect=10.0),
        )
        print(f"[warmup] {LLM_MODEL} ready")
    except Exception as e:
        print(f"[warmup] skipped: {e}")


async def stream_ollama(messages: list[dict]) -> AsyncIterator[dict]:
    buf = ""
    full = ""
    first_chunk_sent = False

    client = _get_client()
    async with client.stream(
        "POST",
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": LLM_MODEL,
            "messages": messages,
            "stream": True,
            "think": LLM_THINK,
            "keep_alive": OLLAMA_KEEP_ALIVE,
            "options": {"num_predict": LLM_MAX_TOKENS},
        },
    ) as resp:
        resp.raise_for_status()
        async for line in resp.aiter_lines():
            if not line.strip():
                continue
            obj = json.loads(line)
            if obj.get("done"):
                break
            token = obj.get("message", {}).get("content", "")
            if not token:
                continue
            buf += token
            full += token
            yield {"type": "token", "text": token}

            if not first_chunk_sent and len(buf) >= _MIN_FIRST_CHARS:
                m = _EARLY_FLUSH.search(buf)
                if m:
                    sentence = buf[:m.end()].strip()
                    if sentence:
                        yield {"type": "sentence", "text": sentence}
                        buf = buf[m.end():]
                        first_chunk_sent = True
                        continue

            m = _SENTENCE_END.search(buf)
            if m:
                sentence = buf[:m.end()].strip()
                if sentence:
                    yield {"type": "sentence", "text": sentence}
                    buf = buf[m.end():]
                    first_chunk_sent = True

    tail = buf.strip()
    if tail:
        yield {"type": "sentence", "text": tail}
    yield {"type": "done", "text": full}
