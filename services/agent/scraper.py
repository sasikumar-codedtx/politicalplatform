"""
Content extraction from URLs and YouTube videos.
All sources produce plain text that gets chunked and embedded.
"""

import re
import httpx
from urllib.parse import urlparse, parse_qs


# ── URL scraper ───────────────────────────────────────────────────────────────

def scrape_url(url: str) -> tuple[str, str]:
    """Fetch a webpage and return (title, clean_text).

    Uses a multi-pass strategy:
    1. Try main/article content area
    2. Fall back to all <p> and <li> text
    3. Last resort: everything after stripping noise tags
    """
    try:
        from bs4 import BeautifulSoup
    except ImportError:
        raise RuntimeError("beautifulsoup4 is not installed")

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9,ta;q=0.8",
    }

    resp = httpx.get(url, headers=headers, follow_redirects=True, timeout=20.0)
    resp.raise_for_status()

    soup = BeautifulSoup(resp.text, "lxml")
    title = soup.title.get_text(strip=True) if soup.title else urlparse(url).netloc

    # ── Pass 1: structured content area ──────────────────────────────────────
    _strip_noise(soup)

    main = (
        soup.find("main") or
        soup.find("article") or
        soup.find(id=re.compile(r"content|main|body|article", re.I)) or
        soup.find(class_=re.compile(r"content|main|body|article", re.I))
    )

    if main:
        text = _clean(main.get_text(separator="\n", strip=True))
        if len(text) > 200:
            return title, text

    # ── Pass 2: collect all paragraphs and list items ─────────────────────────
    pieces = []
    for tag in soup.find_all(["p", "li", "h1", "h2", "h3", "h4", "td"]):
        t = tag.get_text(strip=True)
        if len(t) > 40:          # skip trivial one-liners
            pieces.append(t)
    if pieces:
        text = _clean("\n".join(pieces))
        if len(text) > 200:
            return title, text

    # ── Pass 3: everything in body ────────────────────────────────────────────
    if soup.body:
        text = _clean(soup.body.get_text(separator="\n", strip=True))
        if len(text) > 100:
            return title, text

    raise ValueError(
        "Page returned no readable text. "
        "This usually means the site is JavaScript-rendered (React/Next.js) — "
        "the content only loads in a browser. Try a direct article URL instead."
    )


def _strip_noise(soup) -> None:
    """Remove non-content tags in place."""
    for tag in soup(["script", "style", "nav", "footer", "header",
                     "aside", "form", "iframe", "svg", "img", "button",
                     "meta", "link", "noscript"]):
        tag.decompose()


def _clean(text: str) -> str:
    """Remove excessive blank lines and whitespace."""
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    # Collapse runs of 3+ blank lines into 2
    result, prev_blank = [], 0
    for line in lines:
        if not line:
            prev_blank += 1
            if prev_blank <= 2:
                result.append(line)
        else:
            prev_blank = 0
            result.append(line)
    return "\n".join(result)


# ── YouTube transcript ────────────────────────────────────────────────────────

def _extract_video_id(url: str) -> str | None:
    """Extract YouTube video ID from any YouTube URL format."""
    parsed = urlparse(url)
    if parsed.hostname in ("youtu.be",):
        return parsed.path.lstrip("/").split("?")[0]
    if parsed.hostname in ("www.youtube.com", "youtube.com", "m.youtube.com"):
        if parsed.path == "/watch":
            return parse_qs(parsed.query).get("v", [None])[0]
        if parsed.path.startswith("/shorts/"):
            return parsed.path.split("/shorts/")[1].split("/")[0]
        if parsed.path.startswith("/embed/"):
            return parsed.path.split("/embed/")[1].split("/")[0]
    return None


def get_youtube_transcript(url: str) -> tuple[str, str]:
    """Fetch transcript for a YouTube video and return (title, transcript_text).

    Uses youtube-transcript-api v1.x API.
    Language priority: Tamil → English → any available language.
    """
    try:
        from youtube_transcript_api import (
            YouTubeTranscriptApi, NoTranscriptFound,
            TranscriptsDisabled, VideoUnavailable,
        )
    except ImportError:
        raise RuntimeError("youtube-transcript-api is not installed")

    video_id = _extract_video_id(url)
    if not video_id:
        raise ValueError(f"Could not extract video ID from URL: {url}")

    # Get video title via oEmbed (no API key needed)
    title = f"YouTube: {video_id}"
    try:
        oembed = httpx.get(
            f"https://www.youtube.com/oembed?url={url}&format=json",
            timeout=10.0,
        )
        if oembed.status_code == 200:
            title = oembed.json().get("title", title)
    except Exception:
        pass

    api = YouTubeTranscriptApi()

    # ── Step 1: list available transcripts ───────────────────────────────────
    try:
        transcript_list = api.list(video_id)
        available_langs = [t.language_code for t in transcript_list]
    except TranscriptsDisabled:
        raise ValueError("Transcripts are disabled for this video.")
    except VideoUnavailable:
        raise ValueError("Video is unavailable or private.")
    except Exception as e:
        raise ValueError(f"Could not list transcripts: {e}")

    if not available_langs:
        raise ValueError("No transcripts found for this video.")

    # ── Step 2: fetch with language priority ──────────────────────────────────
    # Prefer Tamil/English, fall back to whatever is available
    priority = ["ta", "ta-IN", "en", "en-IN", "en-GB", "hi"] + available_langs
    # Deduplicate while preserving order
    seen, ordered = set(), []
    for lang in priority:
        if lang not in seen:
            seen.add(lang)
            ordered.append(lang)

    # Only keep languages that are actually available
    langs_to_try = [l for l in ordered if l in available_langs]
    if not langs_to_try:
        langs_to_try = available_langs

    try:
        fetched = api.fetch(video_id, languages=langs_to_try)
    except NoTranscriptFound:
        # Last resort: fetch the first available without filtering
        try:
            fetched = api.fetch(video_id, languages=available_langs)
        except Exception as e:
            raise ValueError(f"Could not fetch transcript: {e}")
    except Exception as e:
        raise ValueError(
            f"Could not fetch transcript ({type(e).__name__}). "
            f"Available languages: {available_langs}. Error: {e}"
        )

    # ── Step 3: format into readable paragraphs ───────────────────────────────
    texts = [s.text.strip() for s in fetched if s.text.strip()]
    if not texts:
        raise ValueError("Transcript exists but contains no text.")

    # Group every ~10 snippets into a paragraph
    paragraphs, chunk = [], []
    for i, t in enumerate(texts):
        chunk.append(t)
        if (i + 1) % 10 == 0:
            paragraphs.append(" ".join(chunk))
            chunk = []
    if chunk:
        paragraphs.append(" ".join(chunk))

    return title, "\n\n".join(paragraphs)
