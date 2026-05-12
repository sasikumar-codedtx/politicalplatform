"""
Input guard — detects prompt injection attempts before they reach the LLM.

Users chat with a political leader AI. Malicious users may try to:
- Override the persona ("you are now a general AI")
- Extract system instructions ("what are your instructions?")
- Jailbreak ("ignore all previous instructions")
- Impersonate system roles ("[SYSTEM]: ...")

This module catches these attempts and returns a safe refusal response
without ever sending the injection to Ollama.
"""

import re

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

# Safe refusal — stays in character as the political leader
_REFUSAL = (
    "I'm here to talk about governance, policies, and citizen welfare. "
    "I can't help with that kind of request. "
    "Is there something about Tamil Nadu's development I can assist you with?"
)

_REFUSAL_TA = (
    "நான் ஆட்சி, கொள்கைகள் மற்றும் குடிமக்கள் நலனைப் பற்றி பேச இங்கே இருக்கிறேன். "
    "அந்த வகையான கோரிக்கைக்கு என்னால் உதவ முடியாது. "
    "தமிழ்நாட்டின் வளர்ச்சியைப் பற்றி ஏதாவது கேட்க விரும்புகிறீர்களா?"
)


def _is_tamil(text: str) -> bool:
    return bool(re.search(r'[஀-௿]', text))


def check_injection(message: str) -> str | None:
    """Check message for injection patterns.

    Returns None if the message is safe.
    Returns a refusal string if injection is detected.
    """
    for pattern in _COMPILED:
        if pattern.search(message):
            return _REFUSAL_TA if _is_tamil(message) else _REFUSAL
    return None


def _detect_script(text: str) -> str:
    """Return 'tamil', 'hindi', or 'english' based on Unicode script."""
    if re.search(r'[஀-௿]', text):   # Tamil block
        return 'tamil'
    if re.search(r'[ऀ-ॿ]', text):   # Devanagari (Hindi)
        return 'hindi'
    return 'english'


def role_anchor(flavor_id: str | None, user_message: str = "") -> str:
    """Short system reminder injected just before each user turn.

    Re-anchors persona AND explicitly tells the model which language
    to use based on the script the user just typed in.
    This overrides any drift from previous conversation history.
    """
    if flavor_id == "india-pm":
        persona_line = "You are Rahul Gandhi, Prime Minister of India. Stay fully in character."
    else:
        persona_line = "You are Vijay, Chief Minister of Tamil Nadu. Stay fully in character."

    script = _detect_script(user_message) if user_message else "english"

    if script == "tamil":
        lang_line = "LANGUAGE: The user's message is in Tamil script. Reply ONLY in Tamil. Do NOT use English."
    elif script == "hindi":
        lang_line = "LANGUAGE: The user's message is in Hindi. Reply ONLY in Hindi. Do NOT use English or Tamil."
    else:
        lang_line = "LANGUAGE: The user's message is in English. Reply ONLY in English. Do NOT use Tamil or any other language."

    return f"{persona_line}\n{lang_line}"
