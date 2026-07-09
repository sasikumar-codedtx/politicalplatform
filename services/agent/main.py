import asyncio
import io
import os
from fastapi import FastAPI, HTTPException, Header, UploadFile, File, Form, WebSocket, WebSocketDisconnect, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from agent import get_reply, get_session_history, get_sessions, clear_session, trim_history
from auth import verify_token
from embeddings import embed
from rag import retrieve_context
from scraper import scrape_url, get_youtube_transcript
from streaming import stream_ollama
from tts import synthesize_sentence
import avatar_client as face_avatar_client
from persona import get_persona
from prompts import get_prompt
from pypdf import PdfReader
from guard import check_injection, role_anchor
from db import (
    init_db,
    audit,
    upsert_document,
    list_documents,
    delete_document,
    search_documents,
    document_count,
    list_audit_logs,
    list_prompts,
    get_prompt_content,
    upsert_prompt,
    ensure_session,
    add_message,
    set_session_title_if_default,
    get_session_messages,
    register_avatar as db_register_avatar,
    list_avatars,
    get_avatar,
    delete_avatar as db_delete_avatar,
)
import uuid as _uuid
from seed_prompts import SEED_PROMPTS, CATEGORY_ORDER, CATEGORY_LABELS
import uvicorn


def _chunk_text(text: str, max_words: int = 350) -> list[str]:
    words = text.split()
    if len(words) <= max_words:
        return [text]
    return [" ".join(words[i:i + max_words]) for i in range(0, len(words), max_words)]


def _embed_and_store(flavor_id: str, title: str, text: str, source: str | None) -> list[int]:
    """Chunk text, embed each chunk, and store it. Returns the new document ids."""
    chunks = _chunk_text(text)
    ids = []
    for i, chunk in enumerate(chunks):
        chunk_title = title if len(chunks) == 1 else f"{title} (part {i+1})"
        doc_id = upsert_document(
            flavor_id=flavor_id,
            title=chunk_title,
            content=chunk,
            embedding=embed(chunk),
            source=source,
        )
        ids.append(doc_id)
    return ids


app = FastAPI(
    title="Political Leader Agent API",
    description="AI agent — citizens talk to their political leader",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request / Response models ────────────────────────────────────────────────

class ChatRequest(BaseModel):
    session_id: str
    message: str
    flavor_id: str | None = None


class ChatResponse(BaseModel):
    session_id: str
    reply: str
    message_count: int


class HistoryResponse(BaseModel):
    session_id: str
    history: list
    message_count: int


class SessionSummary(BaseModel):
    id: str
    title: str
    created_at: str
    last_active_at: str
    last_message: str


class SessionsResponse(BaseModel):
    sessions: list[SessionSummary]
    count: int


class AddDocumentRequest(BaseModel):
    flavor_id: str
    title: str
    content: str
    source: str | None = None


class TestQueryRequest(BaseModel):
    flavor_id: str
    query: str
    top_k: int = 3


class IngestUrlRequest(BaseModel):
    flavor_id: str
    url: str
    source: str | None = None


class IngestYouTubeRequest(BaseModel):
    flavor_id: str
    url: str


class PromptUpdateRequest(BaseModel):
    content: str


# ── Core routes ──────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"service": "Political Leader Agent", "status": "running", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("startup")
def startup():
    init_db()


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest, background_tasks: BackgroundTasks,
               authorization: str | None = Header(default=None)):
    if not req.session_id.strip():
        raise HTTPException(status_code=400, detail="session_id cannot be empty")
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message cannot be empty")

    uid, auth_error = verify_token(authorization)
    if auth_error:
        raise HTTPException(status_code=401, detail=auth_error)

    try:
        reply = get_reply(req.session_id, req.message, req.flavor_id, uid)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Agent error: {str(e)}")

    # Pre-synth the reply in the background, sentence by sentence, so each
    # /tts call mobile makes (one per sentence) sees a cache HIT. Caching
    # the whole reply as a single entry would miss the per-sentence calls.
    background_tasks.add_task(_tts_warm_sentences, reply, None)

    history = get_session_history(req.session_id)
    return ChatResponse(session_id=req.session_id, reply=reply, message_count=len(history))


class TtsRequest(BaseModel):
    text: str
    voice: str | None = None


# ── Disk cache for /tts ──────────────────────────────────────────────────────
# sha256(text + "|" + voice + "|" + engine + "|" + fish_voice_id) → MP3 file
# in services/agent/data/tts_cache/. Hit returns from disk in <10 ms; miss
# calls Fish (~1-3 s) and writes the result for next time. Cache survives
# restarts, no expiry. /chat schedules a background prefetch so the audio
# is usually warm by the time mobile asks for it.
import hashlib as _hashlib
import logging as _logging
import sys as _sys
import time as _time
from pathlib import Path as _Path
from fastapi.responses import Response as _Response

# Uvicorn wires its own loggers, leaving the root logger unconfigured.
# Without our own handler, _tts_log.info(...) gets swallowed and only the
# bare access-log line ("POST /tts ... 200 OK") shows up. Attach a single
# stdout handler so HIT/MISS lines are always visible.
_tts_log = _logging.getLogger("agent.tts")
_tts_log.setLevel(_logging.INFO)
_tts_log.propagate = False
if not _tts_log.handlers:
    _h = _logging.StreamHandler(_sys.stdout)
    _h.setLevel(_logging.INFO)
    _h.setFormatter(_logging.Formatter("%(asctime)s %(message)s", datefmt="%H:%M:%S"))
    _tts_log.addHandler(_h)

_TTS_CACHE_DIR = _Path(__file__).parent / "data" / "tts_cache"
_TTS_CACHE_DIR.mkdir(parents=True, exist_ok=True)


def _tts_cache_summary() -> str:
    files = list(_TTS_CACHE_DIR.glob("*.mp3"))
    kb = sum(f.stat().st_size for f in files) / 1024
    return f"{len(files)} entries, {kb:.1f} KB"


_tts_log.info(f"[TTS] cache dir = {_TTS_CACHE_DIR}  ({_tts_cache_summary()})")


def _tts_cache_path(text: str, voice: str | None) -> _Path:
    h = _hashlib.sha256()
    h.update(text.encode("utf-8"))
    h.update(b"|")
    h.update((voice or "").encode("utf-8"))
    h.update(b"|")
    h.update((os.getenv("TTS_ENGINE", "edge") or "edge").encode("utf-8"))
    h.update(b"|")
    h.update((os.getenv("FISH_AUDIO_VOICE_ID", "") or "").encode("utf-8"))
    return _TTS_CACHE_DIR / f"{h.hexdigest()[:24]}.mp3"


import re as _re
_TTS_SENTENCE_RE = _re.compile(r'[^.!?।]+(?:[.!?।]+|$)')


def _tts_split_sentences(text: str) -> list[str]:
    """Same split rule the mobile client uses, so per-sentence cache keys
    match what mobile asks for. Without this, the per-sentence /tts calls
    miss every entry the background prefetch created."""
    out: list[str] = []
    for m in _TTS_SENTENCE_RE.finditer(text or ""):
        s = (m.group(0) or "").strip()
        if s:
            out.append(s)
    return out or ([text.strip()] if text.strip() else [])


async def _tts_warm(text: str, voice: str | None = None) -> bool:
    """Synth (text, voice) into the cache. Idempotent — returns True if a
    cache file exists after the call (whether from a prior request or a fresh
    synth done here). Never raises — caller can fire-and-forget."""
    text = (text or "").strip()
    if not text:
        return False
    cache_file = _tts_cache_path(text, voice)
    if cache_file.exists() and cache_file.stat().st_size > 0:
        return True
    try:
        audio = await synthesize_sentence(text, voice=voice)
        cache_file.write_bytes(audio)
        _tts_log.info(f"[TTS] prefetch  cached  {len(audio):>6} B  {cache_file.name}  text={text[:40]!r}")
        return True
    except Exception as e:
        _tts_log.warning(f"[TTS] prefetch failed: {e}  text={text[:40]!r}")
        return False


async def _tts_warm_sentences(text: str, voice: str | None = None) -> int:
    """Prefetch each sentence of `text` IN PARALLEL. Fish handles concurrent
    calls fine, so synth time drops from sum(sentences) to max(sentences) —
    a 5-sentence reply goes from ~10s to ~2s. Mobile streams playback as
    each sentence becomes cached, so first audio lands ASAP."""
    sentences = _tts_split_sentences(text)
    if not sentences:
        return 0
    results = await asyncio.gather(
        *[_tts_warm(s, voice) for s in sentences],
        return_exceptions=True,
    )
    cached = sum(1 for r in results if r is True)
    _tts_log.info(f"[TTS] prefetch  parallel  {cached}/{len(sentences)}  reply={text[:60]!r}")
    return cached


@app.post("/tts")
async def tts(req: TtsRequest, strict_cache: bool = False):
    """One-shot text-to-speech. Returns MP3 bytes.

    Disk-cached. X-Cache header is HIT (returned from local disk, ~5 ms) or
    MISS (called Fish, ~1-3 s, then cached for next time).

    `?strict_cache=true` makes the endpoint **cache-only**: 404 on miss
    instead of calling Fish. Used by the per-message speaker button so that
    replays come from our data, never the cloud, and stay silent if the
    audio isn't already cached.
    """
    text = (req.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")

    t0 = _time.perf_counter()
    cache_file = _tts_cache_path(text, req.voice)
    if cache_file.exists() and cache_file.stat().st_size > 0:
        data = cache_file.read_bytes()
        elapsed_ms = (_time.perf_counter() - t0) * 1000
        _tts_log.info(
            f"[TTS] HIT   {len(data):>6} B  in {elapsed_ms:>6.1f} ms  "
            f"cache={cache_file.name}  text={text[:40]!r}"
        )
        return _Response(
            content=data,
            media_type="audio/mpeg",
            headers={
                "Cache-Control": "no-store",
                "X-Cache": "HIT",
                "X-Cache-Ms": f"{elapsed_ms:.1f}",
            },
        )

    if strict_cache:
        elapsed_ms = (_time.perf_counter() - t0) * 1000
        _tts_log.info(
            f"[TTS] MISS-STRICT  in {elapsed_ms:>6.1f} ms  (no Fish call)  "
            f"text={text[:40]!r}"
        )
        raise HTTPException(status_code=404, detail="not in cache")

    try:
        audio = await synthesize_sentence(text, voice=req.voice)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Synthesis failed: {e}")

    try:
        cache_file.write_bytes(audio)
        elapsed_ms = (_time.perf_counter() - t0) * 1000
        _tts_log.info(
            f"[TTS] MISS  {len(audio):>6} B  in {elapsed_ms:>6.1f} ms  "
            f"(Fish call + write)  cache={cache_file.name}  text={text[:40]!r}"
        )
    except Exception as e:
        _tts_log.warning(f"[TTS] MISS (write failed: {e})  text={text[:40]!r}")

    return _Response(
        content=audio,
        media_type="audio/mpeg",
        headers={
            "Cache-Control": "no-store",
            "X-Cache": "MISS",
            "X-Cache-Ms": f"{((_time.perf_counter() - t0) * 1000):.1f}",
        },
    )


@app.post("/tts/cached")
def tts_cached_probe(req: TtsRequest):
    """Lightweight cache probe — does NOT return audio bytes. Splits `text`
    into the same sentences mobile uses, checks each one's cache file, and
    reports whether the whole reply is replayable from disk. Used by the
    mobile per-message speaker icon to decide whether to render itself."""
    text = (req.text or "").strip()
    if not text:
        return {"cached": False, "total": 0, "found": 0}
    sentences = _tts_split_sentences(text)
    found = 0
    for s in sentences:
        f = _tts_cache_path(s, req.voice)
        if f.exists() and f.stat().st_size > 0:
            found += 1
    return {
        "cached": found == len(sentences) and len(sentences) > 0,
        "total":  len(sentences),
        "found":  found,
    }


@app.get("/tts/cache/stats")
def tts_cache_stats():
    """How many entries are in the TTS cache and how big it is. Use this
    after a conversation to confirm caching is actually happening."""
    files = list(_TTS_CACHE_DIR.glob("*.mp3"))
    total = sum(f.stat().st_size for f in files)
    return {
        "cache_dir":  str(_TTS_CACHE_DIR),
        "entries":    len(files),
        "total_kb":   round(total / 1024, 1),
        "newest":     max((f.stat().st_mtime for f in files), default=None),
    }


@app.delete("/tts/cache")
def tts_cache_clear():
    """Wipe the TTS cache. Useful when you change Fish voice id and want
    to force re-synthesis of all phrases."""
    removed = 0
    for f in _TTS_CACHE_DIR.glob("*.mp3"):
        try:
            f.unlink()
            removed += 1
        except Exception:
            pass
    _tts_log.info(f"[TTS] cache cleared — {removed} files removed")
    return {"removed": removed}


@app.get("/sessions", response_model=SessionsResponse)
def sessions(authorization: str | None = Header(default=None)):
    uid, auth_error = verify_token(authorization)
    if auth_error:
        raise HTTPException(status_code=401, detail=auth_error)
    all_sessions = get_sessions(uid)
    return SessionsResponse(sessions=all_sessions, count=len(all_sessions))


@app.get("/history/{session_id}", response_model=HistoryResponse)
def get_history(session_id: str):
    history = get_session_history(session_id)
    return HistoryResponse(session_id=session_id, history=history, message_count=len(history))


@app.delete("/session/{session_id}")
def end_session(session_id: str):
    cleared = clear_session(session_id)
    return {"status": "cleared" if cleared else "not found", "session_id": session_id}


# ── Admin / RAG routes ───────────────────────────────────────────────────────

@app.get("/admin/documents")
def admin_list_documents(flavor_id: str | None = None):
    docs = list_documents(flavor_id)
    return {"documents": docs, "count": len(docs)}


@app.post("/admin/documents")
def admin_add_document(req: AddDocumentRequest):
    ids = _embed_and_store(req.flavor_id, req.title, req.content, req.source)
    audit("document_added", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"title": req.title, "flavor_id": req.flavor_id, "chunks": len(ids), "source": req.source})
    return {"status": "ok", "chunks": len(ids), "ids": ids}


@app.post("/admin/documents/upload")
async def admin_upload_document(
    flavor_id: str = Form(...),
    title: str = Form(...),
    source: str = Form(default=""),
    file: UploadFile = File(...),
):
    content_bytes = await file.read()
    filename = file.filename or ""

    if filename.endswith(".pdf"):
        try:
            reader = PdfReader(io.BytesIO(content_bytes))
            text = "\n".join(page.extract_text() or "" for page in reader.pages)
        except ImportError:
            raise HTTPException(status_code=400, detail="pypdf not installed — PDF upload not available")
    elif filename.endswith(".txt") or filename.endswith(".md"):
        text = content_bytes.decode("utf-8", errors="ignore")
    else:
        raise HTTPException(status_code=400, detail="Only .pdf, .txt, and .md files are supported")

    text = text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="File appears to be empty or unreadable")

    ids = _embed_and_store(flavor_id, title, text, source or filename)
    audit("file_uploaded", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"title": title, "flavor_id": flavor_id, "filename": filename, "chunks": len(ids)})
    return {"status": "ok", "filename": filename, "chunks": len(ids), "ids": ids}


@app.post("/admin/ingest/url")
def admin_ingest_url(req: IngestUrlRequest):
    try:
        page_title, text = scrape_url(req.url)
    except Exception as e:
        audit("url_scrape_failed", metadata={"url": req.url, "flavor_id": req.flavor_id}, status="error", error_msg=str(e))
        raise HTTPException(status_code=422, detail=f"Failed to scrape URL: {e}")

    if not text.strip():
        raise HTTPException(status_code=422, detail="Page returned no readable text")

    title = req.source or page_title
    ids = _embed_and_store(req.flavor_id, title, text, req.url)
    audit("url_scraped", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"url": req.url, "title": title, "flavor_id": req.flavor_id, "chunks": len(ids)})
    return {"status": "ok", "title": title, "url": req.url, "chunks": len(ids), "ids": ids}


@app.post("/admin/ingest/youtube")
def admin_ingest_youtube(req: IngestYouTubeRequest):
    try:
        video_title, transcript = get_youtube_transcript(req.url)
    except Exception as e:
        audit("youtube_ingest_failed", metadata={"url": req.url, "flavor_id": req.flavor_id}, status="error", error_msg=str(e))
        raise HTTPException(status_code=422, detail=f"Failed to get transcript: {e}")

    if not transcript.strip():
        raise HTTPException(status_code=422, detail="No transcript content found")

    ids = _embed_and_store(req.flavor_id, video_title, transcript, req.url)
    audit("youtube_ingested", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"url": req.url, "title": video_title, "flavor_id": req.flavor_id, "chunks": len(ids)})
    return {"status": "ok", "title": video_title, "url": req.url, "chunks": len(ids), "ids": ids}


@app.delete("/admin/documents/{doc_id}")
def admin_delete_document(doc_id: int):
    deleted = delete_document(doc_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Document not found")
    audit("document_deleted", entity_type="document", entity_id=str(doc_id))
    return {"status": "deleted", "id": doc_id}


@app.get("/admin/audit-logs")
def admin_audit_logs(limit: int = 100):
    logs = list_audit_logs(limit)
    return {"logs": logs, "count": len(logs)}


@app.post("/admin/test-query")
def admin_test_query(req: TestQueryRequest):
    count = document_count(req.flavor_id)
    if count == 0:
        return {"results": [], "message": f"No documents found for flavor '{req.flavor_id}'"}

    query_embedding = embed(req.query)
    results = search_documents(req.flavor_id, query_embedding, top_k=req.top_k)
    return {
        "query": req.query,
        "flavor_id": req.flavor_id,
        "results": [
            {
                "title": r["title"],
                "source": r["source"],
                "similarity": round(float(r["similarity"]), 4),
                "preview": r["content"][:300],
            }
            for r in results
        ],
    }


# ── Prompt admin routes ──────────────────────────────────────────────────────

@app.get("/admin/prompts")
def admin_list_prompts():
    rows = list_prompts()
    groups: dict[str, list[dict]] = {cat: [] for cat in CATEGORY_ORDER}
    for r in rows:
        groups.setdefault(r["category"], []).append({
            **r,
            "is_seed_default": (
                r["key"] in SEED_PROMPTS
                and r["content"] == SEED_PROMPTS[r["key"]]["content"]
            ),
            "has_seed_default": r["key"] in SEED_PROMPTS,
        })
    ordered = [{
        "category":   cat,
        "label":      CATEGORY_LABELS.get(cat, cat.title()),
        "prompts":    groups.get(cat, []),
    } for cat in CATEGORY_ORDER if groups.get(cat)]

    # Anything saved under a category we don't know about — surface it too
    for cat, items in groups.items():
        if cat not in CATEGORY_ORDER and items:
            ordered.append({"category": cat, "label": cat.title(), "prompts": items})

    return {"groups": ordered, "count": len(rows)}


@app.get("/admin/prompts/{key:path}")
def admin_get_prompt(key: str):
    stored = get_prompt_content(key)
    seed = SEED_PROMPTS.get(key)
    if stored is None and seed is None:
        raise HTTPException(status_code=404, detail="Unknown prompt key")
    content = stored if stored is not None else seed["content"]
    return {
        "key":            key,
        "content":        content,
        "label":          seed["label"] if seed else key,
        "description":    seed["description"] if seed else "",
        "category":       seed["category"] if seed else "misc",
        "has_seed_default": seed is not None,
        "is_seed_default":  seed is not None and content == seed["content"],
    }


@app.put("/admin/prompts/{key:path}")
def admin_update_prompt(key: str, req: PromptUpdateRequest):
    content = req.content.strip()
    if not content:
        raise HTTPException(status_code=400, detail="content cannot be empty")
    upsert_prompt(key, content)
    audit("prompt_updated", entity_type="prompt", entity_id=key,
          metadata={"key": key, "length": len(content)})
    return {"status": "ok", "key": key, "length": len(content)}


@app.post("/admin/prompts/{key:path}/reset")
def admin_reset_prompt(key: str):
    seed = SEED_PROMPTS.get(key)
    if seed is None:
        raise HTTPException(status_code=404, detail="No seed default for this prompt")
    upsert_prompt(key, seed["content"])
    audit("prompt_reset", entity_type="prompt", entity_id=key, metadata={"key": key})
    return {"status": "reset", "key": key, "length": len(seed["content"])}


# ── Realtime avatar streaming WebSocket ──────────────────────────────────────
#
# Protocol:
#   Client → Server (first frame, JSON):
#     {"type":"user_message","session_id":"...","message":"...",
#      "flavor_id":"tn-tvk","token":"<bearer>"}
#
#   Server → Client (text frames):
#     {"type":"token","text":"..."}                     every LLM token
#     {"type":"sentence","text":"..."}                  every sentence boundary
#     {"type":"audio","index":N,"text":"...",           followed by ONE binary
#      "mime":"audio/mpeg","size":N}                     frame containing the MP3
#     {"type":"done","reply":"<full>"}
#     {"type":"error","detail":"..."}

def _build_chat_messages(session_id: str, user_message: str,
                         flavor_id: str | None, user_id: str | None) -> list[dict]:
    persona = get_persona(flavor_id)
    ensure_session(session_id, persona, flavor_id=flavor_id, user_id=user_id)
    add_message(session_id, "user", user_message)

    title = user_message[:40].strip()
    if len(user_message) > 40:
        title = f"{title}..."
    if title:
        set_session_title_if_default(session_id, title)

    messages = [
        {"role": item["role"], "content": item["content"]}
        for item in get_session_messages(session_id, include_system=True)
    ]
    messages = trim_history(messages)
    if messages and messages[0]["role"] == "system":
        messages[0]["content"] = persona
    else:
        messages.insert(0, {"role": "system", "content": persona})

    messages.insert(len(messages) - 1, {
        "role": "system",
        "content": role_anchor(flavor_id, user_message),
    })

    if flavor_id:
        context = retrieve_context(user_message, flavor_id)
        if context:
            messages.insert(1, {
                "role": "system",
                "content": get_prompt("rag:context_prefix") + context,
            })
    return messages


@app.websocket("/ws/chat")
async def ws_chat(ws: WebSocket):
    await ws.accept()
    try:
        first = await ws.receive_json()
    except Exception:
        await ws.close(code=1003)
        return

    if first.get("type") != "user_message":
        await ws.send_json({"type": "error", "detail": "expected type=user_message"})
        await ws.close(code=1003)
        return

    session_id = (first.get("session_id") or "").strip()
    message    = (first.get("message") or "").strip()
    flavor_id  = first.get("flavor_id")
    token      = first.get("token")
    avatar_id  = (first.get("avatar_id") or "").strip() or None

    # Resolve TTS strategy from the avatar record (if any).
    #   face_avatar_id present  → call avatar-service Piper, return WAV
    #   otherwise              → keep using local edge-tts, return MP3
    selected_avatar = get_avatar(avatar_id) if avatar_id else None
    face_avatar_id  = selected_avatar.get("face_avatar_id") if selected_avatar else None
    piper_voice_id  = selected_avatar.get("piper_voice_id") if selected_avatar else None

    async def synth_one(text: str) -> tuple[bytes, str]:
        if face_avatar_id:
            audio = await face_avatar_client.speak(face_avatar_id, text, voice_id=piper_voice_id)
            return audio, "audio/mpeg"      # avatar-service returns MP3 (edge-tts)

        cache_file = _tts_cache_path(text, None)
        if cache_file.exists() and cache_file.stat().st_size > 0:
            data = cache_file.read_bytes()
            _tts_log.info(f"[TTS] ws-HIT  {len(data):>6} B  cache={cache_file.name}  text={text[:40]!r}")
            return data, "audio/mpeg"

        t0 = _time.perf_counter()
        mp3 = await synthesize_sentence(text)
        elapsed_ms = (_time.perf_counter() - t0) * 1000
        try:
            cache_file.write_bytes(mp3)
        except Exception as e:
            _tts_log.warning(f"[TTS] ws-write failed: {e}")
        _tts_log.info(f"[TTS] ws-MISS {len(mp3):>6} B  in {elapsed_ms:>6.1f} ms  text={text[:40]!r}")
        return mp3, "audio/mpeg"

    if not session_id or not message:
        await ws.send_json({"type": "error", "detail": "session_id and message are required"})
        await ws.close(code=1003)
        return

    auth_header = f"Bearer {token}" if token else None
    uid, auth_error = verify_token(auth_header)
    if auth_error:
        await ws.send_json({"type": "error", "detail": auth_error})
        await ws.close(code=4401)
        return

    blocked = check_injection(message)
    if blocked:
        audit("injection_blocked", entity_type="session", entity_id=session_id,
              metadata={"message_preview": message[:120], "flavor_id": flavor_id})
        await ws.send_json({"type": "token", "text": blocked})
        try:
            audio, mime = await synth_one(blocked)
            await ws.send_json({"type": "audio", "index": 0, "text": blocked,
                                "mime": mime, "size": len(audio)})
            await ws.send_bytes(audio)
        except Exception:
            pass
        await ws.send_json({"type": "done", "reply": blocked})
        await ws.close()
        return

    try:
        messages = _build_chat_messages(session_id, message, flavor_id, uid)
    except Exception as e:
        await ws.send_json({"type": "error", "detail": f"setup error: {e}"})
        await ws.close(code=1011)
        return

    sentence_tasks: list[tuple[int, str, asyncio.Task]] = []
    next_to_send = 0
    full_reply = ""
    producer_done = asyncio.Event()

    async def drain_audio():
        nonlocal next_to_send
        while True:
            if next_to_send < len(sentence_tasks):
                idx, text, task = sentence_tasks[next_to_send]
                try:
                    audio, mime = await task
                except Exception as e:
                    await ws.send_json({"type": "error", "detail": f"tts failed: {e}"})
                    next_to_send += 1
                    continue
                await ws.send_json({"type": "audio", "index": idx, "text": text,
                                    "mime": mime, "size": len(audio)})
                await ws.send_bytes(audio)
                next_to_send += 1
            else:
                if producer_done.is_set():
                    return
                await asyncio.sleep(0.02)

    drain_task = asyncio.create_task(drain_audio())
    try:
        async for evt in stream_ollama(messages):
            etype = evt["type"]
            if etype == "token":
                await ws.send_json({"type": "token", "text": evt["text"]})
            elif etype == "sentence":
                idx = len(sentence_tasks)
                await ws.send_json({"type": "sentence", "text": evt["text"]})
                sentence_tasks.append((
                    idx,
                    evt["text"],
                    asyncio.create_task(synth_one(evt["text"])),
                ))
            elif etype == "done":
                full_reply = evt["text"]
    except WebSocketDisconnect:
        producer_done.set()
        for _, _, task in sentence_tasks:
            task.cancel()
        return
    except Exception as e:
        producer_done.set()
        try:
            await ws.send_json({"type": "error", "detail": str(e)})
        except Exception:
            pass
        await ws.close(code=1011)
        return

    producer_done.set()
    await drain_task

    if full_reply.strip():
        add_message(session_id, "assistant", full_reply)
        audit("chat_message_streamed", entity_type="session", entity_id=session_id,
              metadata={"flavor_id": flavor_id, "message_preview": message[:80]})

    await ws.send_json({"type": "done", "reply": full_reply})
    await ws.close()


# ── Avatar admin routes (Face Photo only) ────────────────────────────────────

@app.post("/admin/avatars/face")
async def admin_avatar_face(
    name: str = Form(...),
    flavor_id: str = Form(default=""),
    voice_id: str = Form(default="en_US-amy-medium"),
    photo: UploadFile = File(...),
):
    """Upload a face photo. Avatar-service stores it + warms its TTS voice.
    We persist the returned upstream avatar_id under our row's
    `face_avatar_id`. /ws/chat uses that to route TTS to avatar-service."""
    content_type = photo.content_type or "image/jpeg"
    if not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image uploads are supported")
    photo_bytes = await photo.read()
    if not photo_bytes:
        raise HTTPException(status_code=400, detail="Empty photo")

    try:
        upstream = await face_avatar_client.register_photo(
            photo_bytes, photo.filename or "photo.jpg", content_type, voice_id=voice_id,
        )
    except face_avatar_client.AvatarServiceError as e:
        raise HTTPException(status_code=502, detail=f"avatar-service unreachable: {e}")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"avatar-service error: {e}")

    avatar_id = _uuid.uuid4().hex
    db_register_avatar(
        avatar_id=avatar_id, name=name.strip(), flavor_id=flavor_id or None,
        face_avatar_id=upstream["avatar_id"], piper_voice_id=upstream["voice_id"],
    )
    audit("avatar_added", entity_type="avatar", entity_id=avatar_id,
          metadata={"name": name, "flavor_id": flavor_id, "source": "face_photo",
                    "voice_id": voice_id, "face_avatar_id": upstream["avatar_id"]})
    return {
        "status": "ok", "id": avatar_id, "name": name,
        "face_avatar_id": upstream["avatar_id"],
        "photo_url": f"{face_avatar_client.AVATAR_SERVICE_URL}{upstream['photo_url']}",
        "voice_id": upstream["voice_id"],
    }


@app.get("/admin/avatars")
def admin_list_avatars(flavor_id: str | None = None):
    items = list_avatars(flavor_id)
    return {"avatars": items, "count": len(items)}


@app.delete("/admin/avatars/{avatar_id}")
async def admin_delete_avatar(avatar_id: str):
    record = get_avatar(avatar_id)
    if not record:
        raise HTTPException(status_code=404, detail="Avatar not found")
    if record.get("face_avatar_id"):
        await face_avatar_client.unregister(record["face_avatar_id"])
    db_delete_avatar(avatar_id)
    audit("avatar_deleted", entity_type="avatar", entity_id=avatar_id)
    return {"status": "deleted", "id": avatar_id}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
