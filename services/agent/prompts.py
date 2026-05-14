"""
Runtime prompt lookup.

Every prompt string used by the agent comes through `get_prompt(key)`.
The DB is the source of truth — `seed_prompts.SEED_PROMPTS` is only a
defensive last-resort fallback if the DB is unreachable or a key is missing.
"""

from db import get_prompt_content
from seed_prompts import SEED_PROMPTS


def get_prompt(key: str) -> str:
    """Look up a prompt by key. Returns the admin-edited content from the DB.

    Falls back to the seed default if the DB row is missing (e.g. brand new
    install before init), or to an empty string if the key is unknown.
    """
    try:
        stored = get_prompt_content(key)
        if stored is not None:
            return stored
    except Exception:
        pass

    seed = SEED_PROMPTS.get(key)
    return seed["content"] if seed else ""
