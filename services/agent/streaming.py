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
LLM_MODEL  = os.getenv("LLM_MODEL", "llama3.2")

# Sentence terminators across scripts (`.` `!` `?` `।` ellipsis)
_SENTENCE_END = re.compile(r"([.!?।]+|\.{3})(\s+|$)")

# First-sentence early flush: comma / semicolon / "but" / "so" etc.
_EARLY_FLUSH  = re.compile(r"([,;:](?=\s))")
_MIN_FIRST_CHARS = 24


async def stream_ollama(messages: list[dict]) -> AsyncIterator[dict]:
    buf = ""
    full = ""
    first_chunk_sent = False

    timeout = httpx.Timeout(120.0, connect=10.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        async with client.stream(
            "POST",
            f"{OLLAMA_URL}/api/chat",
            json={"model": LLM_MODEL, "messages": messages, "stream": True},
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
