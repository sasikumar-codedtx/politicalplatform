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
        # Spell the initials as three separate long-vowel syllables. With the
        # old dotted form ("டி.வி.கே.") Fish treated the periods as breaks and
        # clipped the last letter to a short "க" (ka) instead of the letter
        # name "கே" (kay). Spaces + long vowels make it read "dee vee kay".
        "TVK":         "டீ வீ கே",
        "T.V.K.":      "டீ வீ கே",
        "T.V.K":       "டீ வீ கே",
        "T V K":       "டீ வீ கே",
        "(TVK)":       "டீ வீ கே",
        "Tamil Nadu":  "தமிழ்நாடு",
        "Chennai":     "சென்னை",
        # Use the Tamil sandhi compound (no space between வெற்றி + கழகம்)
        # so Fish reads it as one flowing word instead of "ka-zha-gam" with
        # pauses between syllables. Cover the common English spellings the LLM
        # emits (single/double t, l/zh, Tamil/Tamizh/Thamizh) — any uncovered
        # variant falls back to the English reader and sounds wrong.
        "Tamilaga Vetri Kalagam":    "தமிழக வெற்றிக்கழகம்",
        "Tamilaga Vetri Kazhagam":   "தமிழக வெற்றிக்கழகம்",
        "Tamilaga Vettri Kalagam":   "தமிழக வெற்றிக்கழகம்",
        "Tamilaga Vettri Kazhagam":  "தமிழக வெற்றிக்கழகம்",
        "Tamizhaga Vetri Kazhagam":  "தமிழக வெற்றிக்கழகம்",
        "Tamizhaga Vettri Kazhagam": "தமிழக வெற்றிக்கழகம்",
        "Thamizhaga Vetri Kazhagam": "தமிழக வெற்றிக்கழகம்",
        "Tamilzha Vettri Kazhagam":  "தமிழக வெற்றிக்கழகம்",
        "Vetri Kalagam":             "வெற்றிக்கழகம்",
        "Vetri Kazhagam":            "வெற்றிக்கழகம்",
        "Vettri Kalagam":            "வெற்றிக்கழகம்",
        "Vettri Kazhagam":           "வெற்றிக்கழகம்",
        "Kalagam":                   "கழகம்",
        "Kazhagam":                  "கழகம்",
    },
    "india-pm": {
        # Hindi/English INC context — keep mostly Latin or use Devanagari.
        # "Modi":   "मोदी",
        # "Delhi":  "दिल्ली",
    },
}


# Pre-compile patterns lazily on first use, keyed by flavor.
_CACHE: Dict[str, list[tuple[re.Pattern[str], str]]] = {}


def _bounded(src: str) -> str:
    """Wrap [src] in \\b only on the sides that end in a word character.

    A trailing \\b after punctuation never matches ("T.V.K." at end of a
    sentence, "(TVK)"), which silently disabled those entries.
    """
    left = r"\b" if src[:1].isalnum() else ""
    right = r"\b" if src[-1:].isalnum() else ""
    return f"{left}{re.escape(src)}{right}"


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
        (re.compile(_bounded(src), re.IGNORECASE), dst)
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
