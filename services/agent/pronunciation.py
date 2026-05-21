"""
TTS pronunciation fixes.

Fish Audio (and most cloned voices) read Latin text using English phonemes.
That makes Tamil names spelled in English sound wrong — e.g. "Vijay" reads as
"V-jay" instead of "Vi-jay". For each problem term, we replace the Latin
spelling with either:

  - the native Tamil script (best — the cloned voice pronounces it correctly),
  - or a phonetic respelling (use when Tamil script is not available).

Substitutions are applied ONLY to the TTS input. The text shown in chat
bubbles and stored in the database is unchanged.

To add a new fix:
  1. Find what the voice mispronounces (e.g. "TVK" → "tee vee kay").
  2. Add an entry to FIXES below.
  3. Restart the agent service. No other changes needed.

Word boundaries (\\b) keep replacements from corrupting longer words —
"Vijayan" will NOT be replaced because the regex requires a boundary on
each side. Case-insensitive.
"""
import re
from typing import Dict

# Per-flavor map. Use the flavor_id from app_config. "default" applies to
# every flavor; flavor-specific entries OVERRIDE default for that flavor.
FIXES: Dict[str, Dict[str, str]] = {
    "default": {
        # Add cross-flavor terms here (Indian English place names etc.)
        # "Chennai":     "சென்னை",
        # "Tamil Nadu":  "தமிழ்நாடு",
    },
    "tn-tvk": {
        # TVK leader names — Tamil script makes the cloned voice nail them.
        "Vijay":       "விஜய்",
        "Anand":       "ஆனந்த்",
        "Arunraj":     "அருண்ராஜ்",
        "Aadhav":      "ஆதவ்",
        # Party + state — let the voice say them in Tamil naturally.
        "TVK":         "டி.வி.கே.",
        "(TVK)":       "டி.வி.கே.",
        "Tamil Nadu":  "தமிழ்நாடு",
        "Chennai":     "சென்னை",
        # Use the Tamil sandhi compound (no space between வெற்றி + கழகம்)
        # so Fish reads it as one flowing word instead of "ka-zha-gam" with
        # pauses between syllables.
        "Tamilaga Vettri Kazhagam": "தமிழக வெற்றிக்கழகம்",
        "Tamilzha Vettri Kazhagam": "தமிழக வெற்றிக்கழகம்",
        "Vettri Kazhagam":          "வெற்றிக்கழகம்",
        "Kazhagam":                 "கழகம்",
    },
    "india-pm": {
        # Hindi/English INC context — keep mostly Latin or use Devanagari.
        # "Modi":   "मोदी",
        # "Delhi":  "दिल्ली",
    },
}


# Pre-compile patterns lazily on first use, keyed by flavor.
_CACHE: Dict[str, list[tuple[re.Pattern[str], str]]] = {}


def _patterns_for(flavor_id: str) -> list[tuple[re.Pattern[str], str]]:
    if flavor_id in _CACHE:
        return _CACHE[flavor_id]

    # Merge default + flavor-specific. Flavor wins on conflict.
    merged: Dict[str, str] = {}
    merged.update(FIXES.get("default", {}))
    merged.update(FIXES.get(flavor_id, {}))

    # Longest-first so "Tamil Nadu" matches before "Tamil".
    items = sorted(merged.items(), key=lambda kv: -len(kv[0]))
    compiled = [
        (re.compile(rf"\b{re.escape(src)}\b", re.IGNORECASE), dst)
        for src, dst in items
    ]
    _CACHE[flavor_id] = compiled
    return compiled


def apply_pronunciation(text: str, flavor_id: str = "tn-tvk") -> str:
    """
    Rewrite [text] so the TTS engine pronounces problem terms correctly.

    Pure function — same input always returns the same output, so the TTS
    disk cache (keyed by the ORIGINAL text upstream) stays consistent: the
    bytes stored are always the bytes a re-call would produce.
    """
    if not text:
        return text
    for pattern, replacement in _patterns_for(flavor_id):
        text = pattern.sub(replacement, text)
    return text
