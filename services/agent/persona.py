"""
Persona resolver.

No prompt text lives here. The active system prompt for a flavor is whatever
the admin has saved under the key `persona:<flavor_id>` in the prompts table.
Factory defaults are seeded once on init from `seed_prompts.py`.
"""

from prompts import get_prompt

DEFAULT_FLAVOR_ID = "tn-tvk"


def get_persona(flavor_id: str | None) -> str:
    flavor = flavor_id or DEFAULT_FLAVOR_ID
    return get_prompt(f"persona:{flavor}")
