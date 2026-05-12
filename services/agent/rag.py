from embeddings import embed
from db import search_documents, document_count

# Only inject context if similarity is above this threshold.
# Calibrated from observed score ranges:
#   - Clearly relevant (e.g. "free bus scheme"): 0.82+
#   - Somewhat relevant (e.g. "housing"): 0.57+
#   - Noise / greetings (e.g. "hello"): 0.45–0.50
# 0.55 catches real policy questions while filtering conversational noise.
SIMILARITY_THRESHOLD = 0.55


def retrieve_context(query: str, flavor_id: str, top_k: int = 3) -> str | None:
    """Search the documents DB for chunks relevant to the query.

    Returns a formatted context string to inject into the prompt,
    or None if no relevant documents are found or DB is empty.

    How it works:
    1. Convert the user's query into a vector (embed it)
    2. Ask PostgreSQL: "find me the top_k document chunks whose
       vectors are closest to this query vector"
    3. Filter out low-similarity results (noise)
    4. Format and return as a context block
    """
    if document_count(flavor_id) == 0:
        return None

    query_embedding = embed(query)
    results = search_documents(flavor_id, query_embedding, top_k=top_k)

    relevant = [r for r in results if r["similarity"] >= SIMILARITY_THRESHOLD]
    if not relevant:
        return None

    lines = []
    for r in relevant:
        lines.append(f"[{r['title']}]\n{r['content']}")

    return "\n\n---\n\n".join(lines)
