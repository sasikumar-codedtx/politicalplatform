from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from agent import get_reply, get_session_history, get_sessions, clear_session
from db import init_db
import uvicorn

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


class ChatRequest(BaseModel):
    session_id: str
    message: str
    persona: str | None = None  # flavor-specific system prompt, used only on session init


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
def chat(req: ChatRequest):
    if not req.session_id.strip():
        raise HTTPException(status_code=400, detail="session_id cannot be empty")
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message cannot be empty")

    try:
        reply = get_reply(req.session_id, req.message, req.persona)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Agent error: {str(e)}")

    history = get_session_history(req.session_id)
    return ChatResponse(session_id=req.session_id, reply=reply, message_count=len(history))


@app.get("/sessions", response_model=SessionsResponse)
def sessions():
    all_sessions = get_sessions()
    return SessionsResponse(sessions=all_sessions, count=len(all_sessions))


@app.get("/history/{session_id}", response_model=HistoryResponse)
def get_history(session_id: str):
    history = get_session_history(session_id)
    return HistoryResponse(session_id=session_id, history=history, message_count=len(history))


@app.delete("/session/{session_id}")
def end_session(session_id: str):
    cleared = clear_session(session_id)
    return {"status": "cleared" if cleared else "not found", "session_id": session_id}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
