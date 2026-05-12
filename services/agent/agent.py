import httpx
import os
from dotenv import load_dotenv
from persona import get_persona
from rag import retrieve_context
from guard import check_injection, role_anchor
from db import (
    add_message,
    audit,
    delete_session,
    ensure_session,
    get_session_messages,
    list_sessions,
    set_session_title_if_default,
)

load_dotenv("../../.env")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL  = os.getenv("LLM_MODEL", "llama3.2")


def get_reply(session_id: str, user_message: str, flavor_id: str | None = None, user_id: str | None = None) -> str:
    # Persona is resolved on the server from flavor_id — never sent from the client
    persona = get_persona(flavor_id)

    # Layer 1 — Injection guard: block before touching the DB or LLM
    injection_response = check_injection(user_message)
    if injection_response:
        audit("injection_blocked", entity_type="session", entity_id=session_id,
              metadata={"message_preview": user_message[:120], "flavor_id": flavor_id})
        return injection_response

    ensure_session(session_id, persona, flavor_id=flavor_id, user_id=user_id)
    add_message(session_id, "user", user_message)

    title = user_message[:40].strip()
    if len(user_message) > 40:
        title = f"{title}..."
    if title:
        set_session_title_if_default(session_id, title)

    # Fetch full conversation history from DB
    messages = [
        {"role": item["role"], "content": item["content"]}
        for item in get_session_messages(session_id, include_system=True)
    ]

    # Layer 2 — Role anchor: inserted BEFORE the last user message.
    # Passes user_message so the anchor includes an explicit language instruction
    # based on the script the user typed in (Tamil / Hindi / English).
    messages.insert(len(messages) - 1, {
        "role": "system",
        "content": role_anchor(flavor_id, user_message),
    })

    # RAG: find relevant policy/scheme chunks and inject right after the persona
    if flavor_id:
        context = retrieve_context(user_message, flavor_id)
        if context:
            messages.insert(1, {
                "role": "system",
                "content": (
                    "RELEVANT CONTEXT — use the information below to answer accurately. "
                    "Do not make up facts. If the context covers the question, use it:\n\n"
                    + context
                ),
            })

    response = httpx.post(
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": LLM_MODEL,
            "messages": messages,
            "stream": False,
        },
        timeout=120.0,
    )
    response.raise_for_status()
    reply = response.json()["message"]["content"]
    # Strip <think>...</think> blocks emitted by reasoning models (e.g. gpt-oss)
    # before storing or returning to the user.
    import re as _re
    reply = _re.sub(r"<think>.*?</think>", "", reply, flags=_re.DOTALL).strip()
    add_message(session_id, "assistant", reply)
    audit("chat_message", entity_type="session", entity_id=session_id,
          metadata={"flavor_id": flavor_id, "message_preview": user_message[:80]})

    return reply


def get_session_history(session_id: str) -> list:
    return get_session_messages(session_id, include_system=False)


def get_sessions(user_id: str | None = None) -> list[dict]:
    return list_sessions(user_id)


def clear_session(session_id: str) -> bool:
    deleted = delete_session(session_id)
    if deleted:
        audit("session_deleted", entity_type="session", entity_id=session_id)
    return deleted
