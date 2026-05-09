import httpx
import os
from dotenv import load_dotenv
from persona import DEFAULT_PERSONA

load_dotenv("../../.env")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL  = os.getenv("LLM_MODEL", "llama3.2")

# In-memory session store: { "session_id": [ {role, content}, ... ] }
sessions: dict[str, list] = {}


def get_reply(session_id: str, user_message: str, persona: str | None = None) -> str:
    if session_id not in sessions:
        resolved_persona = persona.strip() if persona and persona.strip() else DEFAULT_PERSONA
        sessions[session_id] = [
            {"role": "system", "content": resolved_persona}
        ]

    sessions[session_id].append({
        "role": "user",
        "content": user_message
    })

    response = httpx.post(
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": LLM_MODEL,
            "messages": sessions[session_id],
            "stream": False
        },
        timeout=60.0
    )
    response.raise_for_status()
    reply = response.json()["message"]["content"]

    sessions[session_id].append({
        "role": "assistant",
        "content": reply
    })

    return reply


def get_session_history(session_id: str) -> list:
    if session_id not in sessions:
        return []
    return [m for m in sessions[session_id] if m["role"] != "system"]


def clear_session(session_id: str) -> bool:
    if session_id in sessions:
        del sessions[session_id]
        return True
    return False
