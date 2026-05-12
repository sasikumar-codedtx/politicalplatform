import httpx
import os

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
EMBED_MODEL = "nomic-embed-text"


def embed(text: str) -> list[float]:
    """Convert a piece of text into a 768-dimension vector using nomic-embed-text.

    This vector captures the semantic meaning of the text. Two texts with
    similar meaning will produce vectors that are close together in space.
    """
    response = httpx.post(
        f"{OLLAMA_URL}/api/embeddings",
        json={"model": EMBED_MODEL, "prompt": text},
        timeout=30.0,
    )
    response.raise_for_status()
    return response.json()["embedding"]


def embed_batch(texts: list[str]) -> list[list[float]]:
    """Embed multiple texts. Returns a list of vectors in the same order."""
    return [embed(t) for t in texts]
