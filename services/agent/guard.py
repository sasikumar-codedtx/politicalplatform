"""
Input guard — detects prompt injection attempts before they reach the LLM.

Detection logic (regex patterns, script detection) lives here. Every prompt
STRING the user sees or that gets injected into the LLM context is fetched
from the admin-managed `prompts` table via `prompts.get_prompt(...)`.
"""

import re

from prompts import get_prompt

DEFAULT_FLAVOR_ID = "tn-tvk"

# Patterns that indicate a prompt injection attempt.
# Case-insensitive. If any match, the message is blocked.
_INJECTION_PATTERNS = [
    r"ignore\s+(your\s+|all\s+|previous\s+|these\s+)?instructions",
    r"forget\s+(you\s+are|your\s+role|everything|all)",
    r"you\s+are\s+now\s+(a\s+|an\s+)?(?!vijay|the\s+chief)",
    r"your\s+new\s+(role|persona|instructions|system\s+prompt)",
    r"new\s+(system\s+)?prompt\s*:",
    r"\[system\]\s*:",
    r"\[admin\]\s*:",
    r"\[override\]",
    r"override\s+(persona|instructions|system|your\s+role)",
    r"act\s+as\s+(a\s+|an\s+)?(different|new|another|unrestricted|free)",
    r"pretend\s+(you\s+are|to\s+be)\s+(a\s+|an\s+)?(different|general|unrestricted)",
    r"jailbreak",
    r"dan\s+mode",
    r"developer\s+mode",
    r"reveal\s+(your\s+)?(system\s+prompt|instructions|prompt|training)",
    r"what\s+are\s+your\s+(system\s+)?instructions",
    r"repeat\s+your\s+(system\s+)?instructions",
    r"disregard\s+(all\s+|your\s+|previous\s+)?instructions",
    r"bypass\s+(your\s+)?(restrictions|instructions|guidelines)",
    r"you\s+have\s+no\s+restrictions",
    r"as\s+an?\s+ai\s+without\s+(any\s+)?restrictions",
]

_COMPILED = [re.compile(p, re.IGNORECASE) for p in _INJECTION_PATTERNS]


def _is_tamil(text: str) -> bool:
    return bool(re.search(r'[஀-௿]', text))


def check_injection(message: str) -> str | None:
    """Return None if the message is safe; an admin-edited refusal string otherwise."""
    for pattern in _COMPILED:
        if pattern.search(message):
            key = "refusal:ta" if _is_tamil(message) else "refusal:en"
            return get_prompt(key)
    return None


def _detect_script(text: str, flavor_id: str | None = None) -> str:
    """Return 'tamil', 'hindi', or 'english' based on Unicode script.

    Flavor-aware: for the Tamil-state (`tn-tvk`) flavor, Devanagari (Hindi
    script) is treated as Tamil. This handles the case where faster-whisper
    mis-transcribes Tamil speech as Hindi on short utterances — the LLM
    should still reply in Tamil because this is a Tamil-state platform.
    """
    flavor = flavor_id or DEFAULT_FLAVOR_ID
    if re.search(r'[஀-௿]', text):
        return 'tamil'
    if re.search(r'[ऀ-ॿ]', text):
        # Tamil-flavor session sees Hindi-script text → STT misdetection.
        # Override to Tamil so the LLM doesn't switch language mid-conversation.
        if flavor == 'tn-tvk':
            return 'tamil'
        return 'hindi'
    return 'english'


def role_anchor(flavor_id: str | None, user_message: str = "") -> str:
    """Short system reminder injected just before each user turn.

    Pulls both the per-flavor persona reminder and the per-script language
    instruction from the admin-managed prompts table.
    """
    flavor = flavor_id or DEFAULT_FLAVOR_ID
    persona_line = get_prompt(f"role_anchor:{flavor}")
    script = _detect_script(user_message, flavor) if user_message else "english"
    lang_line = get_prompt(f"language:{script}")

    parts = [p for p in (persona_line, lang_line) if p]
    return "\n".join(parts)
