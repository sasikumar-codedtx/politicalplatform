import httpx
import os
from dotenv import load_dotenv
from persona import DEFAULT_PERSONA
from db import (
    add_message,
    delete_session,
    ensure_session,
    get_session_messages,
    list_sessions,
    set_session_title_if_default,
)

load_dotenv("../../.env")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL  = os.getenv("LLM_MODEL", "llama3.2")


def get_reply(session_id: str, user_message: str, persona: str | None = None) -> str:
    resolved_persona = persona.strip() if persona and persona.strip() else DEFAULT_PERSONA
    ensure_session(session_id, resolved_persona)
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

    response = httpx.post(
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": LLM_MODEL,
            "messages": messages,
            "stream": False
        },
        timeout=60.0
    )
    response.raise_for_status()
    reply = response.json()["message"]["content"]
    add_message(session_id, "assistant", reply)

    return reply


def get_session_history(session_id: str) -> list:
    return get_session_messages(session_id, include_system=False)


def get_sessions() -> list[dict]:
    return list_sessions()


def clear_session(session_id: str) -> bool:
    return delete_session(session_id)
