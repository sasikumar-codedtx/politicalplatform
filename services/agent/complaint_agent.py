"""Autonomous complaint-intake agent.

When a citizen describes a civic problem in the chat (in any language), this
files it as an official complaint via the existing complaints backend and
returns a confirmation in their own language. It reuses the same Ollama model
the chat uses — one extra JSON call, gated behind a cheap keyword check so
ordinary chat never pays for it.
"""
import json
import os
import re

import httpx

from db import add_complaint, audit

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-oss:20b-cloud")

# Cheap gate — only spend an LLM call when the message looks like a grievance.
# Covers English + Tamil + Hindi complaint words and common civic nouns.
_GATE = re.compile(
    r"complaint|complain|problem|issue|grievance|register|"
    r"water|electric|current|power|road|garbage|drainage|sewage|street\s*light|"
    r"புகார்|பிரச்ச|சிக்கல|கோரிக்கை|தண்ணீர்|மின்சாரம்|சாலை|குப்பை|"
    r"शिकायत|समस्या|परेशानी|पानी|बिजली|सड़क|कचरा",
    re.IGNORECASE,
)

_PROMPT = (
    "You are a civic-complaint intake assistant for a government app. Read the "
    "user's message. If the user is REPORTING A CIVIC PROBLEM they want raised as "
    "an official complaint (water, electricity, roads, garbage, drainage, health, "
    "etc.), respond ONLY with this JSON: "
    '{"is_complaint": true, "title": "<short title in the user\'s language>", '
    '"description": "<the problem in the user\'s language>", '
    '"category": "<Water|Electricity|Roads|Sanitation|Health|Education|Other>", '
    '"reply": "<one warm sentence in the user\'s language confirming the complaint '
    'was registered>"}. '
    "If it is NOT a complaint (greeting, question, opinion, small talk), respond "
    'ONLY with {"is_complaint": false}. No markdown, no extra text.'
)


def try_raise_complaint(message: str, flavor_id: str | None,
                        uid: str, device_id: str = "") -> str | None:
    """Returns a confirmation reply if a complaint was filed, else None."""
    if not message or not _GATE.search(message):
        return None
    try:
        resp = httpx.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": LLM_MODEL,
                "messages": [
                    {"role": "system", "content": _PROMPT},
                    {"role": "user", "content": message},
                ],
                "stream": False,
                "think": False,
                "format": "json",
                "keep_alive": -1,
                "options": {"num_predict": 300, "temperature": 0},
            },
            timeout=60.0,
        )
        resp.raise_for_status()
        data = json.loads(resp.json()["message"]["content"])
    except Exception:
        return None

    if not isinstance(data, dict) or not data.get("is_complaint"):
        return None

    title = (data.get("title") or message[:60]).strip()
    description = (data.get("description") or message).strip()
    category = (data.get("category") or "Other").strip()
    try:
        row = add_complaint(uid or "", device_id or "", title, description, category)
        audit("complaint_created_via_chat", entity_type="complaint",
              entity_id=str(row["id"]), metadata={"category": category})
    except Exception:
        return None

    return (data.get("reply")
            or "Your complaint has been registered. We will look into it.").strip()
