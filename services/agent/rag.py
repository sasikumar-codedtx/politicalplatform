import re
import time
from embeddings import embed
from db import search_documents, document_count

# Only inject context if similarity is above this threshold.
# Calibrated from observed score ranges:
#   - Clearly relevant (e.g. "free bus scheme"): 0.82+
#   - Somewhat relevant (e.g. "housing"): 0.57+
#   - Noise / greetings (e.g. "hello"): 0.45–0.50
# 0.55 catches real policy questions while filtering conversational noise.
SIMILARITY_THRESHOLD = 0.55

# Greetings / acknowledgements that never need document retrieval. Skipping
# them avoids an embedding round-trip + vector search on the chat hot path,
# shaving that latency off time-to-first-token.
_TRIVIAL = re.compile(
    r'^(hi+|hello+|hey+|vanakkam|வணக்கம்|thanks?|thank you|ok(ay)?|hmm+|'
    r'yes|no|bye|good (morning|evening|night)|நன்றி)\b',
    re.IGNORECASE,
)


def _is_trivial(query: str) -> bool:
    q = (query or "").strip()
    if len(q) < 4:
        return True
    return len(q.split()) <= 3 and _TRIVIAL.match(q) is not None


# Cache "does this flavor have documents?" for a short window so the chat hot
# path doesn't run a COUNT query every turn. Picks up newly-added docs in <=TTL.
_DOC_CACHE_TTL = 60.0
_doc_cache: dict[str, tuple[float, bool]] = {}


def _has_documents(flavor_id: str) -> bool:
    now = time.time()
    hit = _doc_cache.get(flavor_id)
    if hit and now - hit[0] < _DOC_CACHE_TTL:
        return hit[1]
    has = document_count(flavor_id) > 0
    _doc_cache[flavor_id] = (now, has)
    return has


def retrieve_context(query: str, flavor_id: str, top_k: int = 3) -> str | None:
    """Search the documents DB for chunks relevant to the query.

    Returns a formatted context string to inject into the prompt,
    or None if no relevant documents are found or DB is empty.

    Trivial messages (greetings/acks) skip retrieval entirely so the LLM
    starts streaming without waiting on an embed + vector search.
    """
    if _is_trivial(query) or not _has_documents(flavor_id):
        return None

    query_embedding = embed(query)
    results = search_documents(flavor_id, query_embedding, top_k=top_k)

    relevant = [r for r in results if r["similarity"] >= SIMILARITY_THRESHOLD]
    if not relevant:
        return None

    lines = [f"[{r['title']}]\n{r['content']}" for r in relevant]
    return "\n\n---\n\n".join(lines)
