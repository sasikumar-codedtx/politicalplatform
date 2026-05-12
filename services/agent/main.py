import io
from fastapi import FastAPI, HTTPException, Header, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from agent import get_reply, get_session_history, get_sessions, clear_session
from auth import verify_token
from embeddings import embed
from rag import retrieve_context
from scraper import scrape_url, get_youtube_transcript
from db import (
    init_db,
    audit,
    upsert_document,
    list_documents,
    delete_document,
    search_documents,
    document_count,
    list_audit_logs,
)
import uvicorn


def _chunk_text(text: str, max_words: int = 350) -> list[str]:
    words = text.split()
    if len(words) <= max_words:
        return [text]
    return [" ".join(words[i:i + max_words]) for i in range(0, len(words), max_words)]


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
def chat(req: ChatRequest, authorization: str | None = Header(default=None)):
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

    history = get_session_history(req.session_id)
    return ChatResponse(session_id=req.session_id, reply=reply, message_count=len(history))


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
    chunks = _chunk_text(req.content)
    ids = []
    for i, chunk in enumerate(chunks):
        title = req.title if len(chunks) == 1 else f"{req.title} (part {i+1})"
        vector = embed(chunk)
        doc_id = upsert_document(
            flavor_id=req.flavor_id,
            title=title,
            content=chunk,
            embedding=vector,
            source=req.source,
        )
        ids.append(doc_id)
    audit("document_added", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"title": req.title, "flavor_id": req.flavor_id, "chunks": len(chunks), "source": req.source})
    return {"status": "ok", "chunks": len(chunks), "ids": ids}


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
            from pypdf import PdfReader
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

    chunks = _chunk_text(text)
    ids = []
    for i, chunk in enumerate(chunks):
        chunk_title = title if len(chunks) == 1 else f"{title} (part {i+1})"
        vector = embed(chunk)
        doc_id = upsert_document(
            flavor_id=flavor_id,
            title=chunk_title,
            content=chunk,
            embedding=vector,
            source=source or filename,
        )
        ids.append(doc_id)

    audit("file_uploaded", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"title": title, "flavor_id": flavor_id, "filename": filename, "chunks": len(chunks)})
    return {"status": "ok", "filename": filename, "chunks": len(chunks), "ids": ids}


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
    chunks = _chunk_text(text)
    ids = []
    for i, chunk in enumerate(chunks):
        chunk_title = title if len(chunks) == 1 else f"{title} (part {i+1})"
        vector = embed(chunk)
        doc_id = upsert_document(flavor_id=req.flavor_id, title=chunk_title,
                                  content=chunk, embedding=vector, source=req.url)
        ids.append(doc_id)

    audit("url_scraped", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"url": req.url, "title": title, "flavor_id": req.flavor_id, "chunks": len(chunks)})
    return {"status": "ok", "title": title, "url": req.url, "chunks": len(chunks), "ids": ids}


@app.post("/admin/ingest/youtube")
def admin_ingest_youtube(req: IngestYouTubeRequest):
    try:
        video_title, transcript = get_youtube_transcript(req.url)
    except Exception as e:
        audit("youtube_ingest_failed", metadata={"url": req.url, "flavor_id": req.flavor_id}, status="error", error_msg=str(e))
        raise HTTPException(status_code=422, detail=f"Failed to get transcript: {e}")

    if not transcript.strip():
        raise HTTPException(status_code=422, detail="No transcript content found")

    chunks = _chunk_text(transcript)
    ids = []
    for i, chunk in enumerate(chunks):
        chunk_title = video_title if len(chunks) == 1 else f"{video_title} (part {i+1})"
        vector = embed(chunk)
        doc_id = upsert_document(flavor_id=req.flavor_id, title=chunk_title,
                                  content=chunk, embedding=vector, source=req.url)
        ids.append(doc_id)

    audit("youtube_ingested", entity_type="document", entity_id=str(ids[0]) if ids else None,
          metadata={"url": req.url, "title": video_title, "flavor_id": req.flavor_id, "chunks": len(chunks)})
    return {"status": "ok", "title": video_title, "url": req.url, "chunks": len(chunks), "ids": ids}


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


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
