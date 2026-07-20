import httpx
import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env from the project root. Absolute path — survives whatever cwd
# uvicorn's reloader subprocess decides to use (the relative form
# "../../.env" silently no-ops when cwd shifts, which is what was making
# DATABASE_URL fall back to its hardcoded default).
_ENV_PATH = Path(__file__).resolve().parents[2] / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)

from persona import get_persona
from prompts import get_prompt
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

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL  = os.getenv("LLM_MODEL", "gpt-oss:20b-cloud")

# Latency knobs:
# - KEEP_ALIVE keeps the model resident so consecutive turns skip the
#   multi-second reload (default: never unload).
# - THINK=false stops the reasoning model from emitting <think> tokens we
#   only throw away — typically the single biggest latency win.
# - MAX_TOKENS caps reply length so the model can't ramble past the persona's
#   3-5 sentence target.
def _keep_alive():
    # Ollama accepts an int (seconds; -1 = never unload) or a duration string
    # like "24h". A bare "-1" STRING is rejected ("missing unit"), so coerce
    # numeric values to int.
    v = os.getenv("OLLAMA_KEEP_ALIVE", "-1")
    try:
        return int(v)
    except ValueError:
        return v


OLLAMA_KEEP_ALIVE = _keep_alive()
LLM_THINK  = os.getenv("LLM_THINK", "false").lower() in ("1", "true", "yes", "on")
LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "512"))

# Keep at most this many user+assistant turns. The system message and any
# transient role-anchor/RAG context messages are kept separately. Long
# histories add 50-200ms per turn to Ollama Cloud's prompt-processing.
HISTORY_TURNS = int(os.getenv("HISTORY_TURNS", "6"))


def trim_history(messages: list[dict], turns: int = HISTORY_TURNS) -> list[dict]:
    """Keep [system messages] + the last 2*turns user/assistant messages."""
    system_msgs = [m for m in messages if m.get("role") == "system"]
    chat_msgs   = [m for m in messages if m.get("role") != "system"]
    if len(chat_msgs) > turns * 2:
        chat_msgs = chat_msgs[-turns * 2:]
    return system_msgs + chat_msgs


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

    # Fetch full conversation history from DB, then trim to last HISTORY_TURNS
    # turns so prompt-processing stays fast on long sessions.
    messages = [
        {"role": item["role"], "content": item["content"]}
        for item in get_session_messages(session_id, include_system=True)
    ]
    messages = trim_history(messages)

    # Always use the latest persona from the admin DB — override the stored
    # system message so edits in the admin UI take effect on the next turn
    # without users needing to start a new session.
    if messages and messages[0]["role"] == "system":
        messages[0]["content"] = persona
    else:
        messages.insert(0, {"role": "system", "content": persona})

    # Layer 2 — Role anchor: inserted BEFORE the last user message.
    # Passes user_message so the anchor includes an explicit language instruction
    # based on the script the user typed in (Tamil / Hindi / English).
    messages.insert(len(messages) - 1, {
        "role": "system",
        "content": role_anchor(flavor_id, user_message),
    })

    # RAG: find relevant policy/scheme chunks and inject right after the persona.
    # The wrapper text is admin-editable (key: rag:context_prefix).
    if flavor_id:
        context = retrieve_context(user_message, flavor_id)
        if context:
            messages.insert(1, {
                "role": "system",
                "content": get_prompt("rag:context_prefix") + context,
            })

    response = httpx.post(
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": LLM_MODEL,
            "messages": messages,
            "stream": False,
            "think": LLM_THINK,
            "keep_alive": OLLAMA_KEEP_ALIVE,
            "options": {"num_predict": LLM_MAX_TOKENS},
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
