"""Community ("Posts" tab) posts for a YouTube channel.

The Data API has no endpoint for the Posts tab, so this reads the public page
and pulls the `ytInitialData` blob out of it. That is an unofficial surface: if
YouTube changes the page shape this returns an empty list and callers carry on
without official posts rather than failing.
"""
import json
import re
import time
from datetime import datetime, timedelta, timezone

import urllib.request

_URL = "https://www.youtube.com/@{handle}/posts"
_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Accept-Language": "en-US,en;q=0.9",
}
_INITIAL_DATA = re.compile(r"ytInitialData\s*=\s*(\{.*?\});", re.S)

_UNITS = {
    "second": 1, "minute": 60, "hour": 3600, "day": 86400,
    "week": 604800, "month": 2592000, "year": 31536000,
}
_AGO = re.compile(r"(\d+)\s+(second|minute|hour|day|week|month|year)s?\s+ago")

_cache: dict[str, tuple[float, list[dict]]] = {}
_TTL = 1800


def _walk(node, out: list) -> None:
    if isinstance(node, dict):
        if "backstagePostThreadRenderer" in node:
            out.append(node["backstagePostThreadRenderer"])
        for v in node.values():
            _walk(v, out)
    elif isinstance(node, list):
        for v in node:
            _walk(v, out)


def _runs_text(block: dict) -> str:
    return "".join(r.get("text", "") for r in (block or {}).get("runs", []))


def _published_at(post: dict) -> datetime:
    label = _runs_text(post.get("publishedTimeText", {})) or \
        post.get("publishedTimeText", {}).get("simpleText", "")
    m = _AGO.search(label.lower())
    if not m:
        return datetime.now(timezone.utc)
    return datetime.now(timezone.utc) - timedelta(
        seconds=int(m.group(1)) * _UNITS[m.group(2)]
    )


def _attachment(post: dict) -> tuple[str, str]:
    """(media_type, media_url) for the post's image or video thumbnail."""
    att = post.get("backstageAttachment") or {}
    image = att.get("backstageImageRenderer")
    if image:
        thumbs = (image.get("image") or {}).get("thumbnails") or []
        if thumbs:
            return "image", thumbs[-1].get("url", "")
    video = att.get("videoRenderer")
    if video:
        thumbs = (video.get("thumbnail") or {}).get("thumbnails") or []
        if thumbs:
            return "video", thumbs[-1].get("url", "")
    return "none", ""


def fetch_channel_posts(handle: str, limit: int = 15) -> list[dict]:
    handle = (handle or "").lstrip("@")
    if not handle:
        return []
    hit = _cache.get(handle)
    if hit and time.time() - hit[0] < _TTL:
        return hit[1]

    try:
        req = urllib.request.Request(_URL.format(handle=handle), headers=_HEADERS)
        with urllib.request.urlopen(req, timeout=20) as res:
            html = res.read().decode("utf-8", "ignore")
        match = _INITIAL_DATA.search(html)
        if not match:
            return []
        threads: list = []
        _walk(json.loads(match.group(1)), threads)

        posts = []
        for thread in threads[:limit]:
            post = (thread.get("post") or {}).get("backstagePostRenderer") or {}
            post_id = post.get("postId")
            text = _runs_text(post.get("contentText", {}))
            if not post_id or (not text and not post.get("backstageAttachment")):
                continue
            media_type, media_url = _attachment(post)
            posts.append({
                "external_id": post_id,
                "user_name": _runs_text(post.get("authorText", {}))
                             or "Tamilaga Vettri Kazhagam",
                "text": text,
                "media_type": media_type,
                "media_url": media_url,
                "link_url": f"https://www.youtube.com/post/{post_id}",
                "created_at": _published_at(post),
            })
    except Exception:
        return []

    _cache[handle] = (time.time(), posts)
    return posts
