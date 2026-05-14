"""
MJPEG multipart/x-mixed-replace response helper.

Browsers natively render this format inside <img src="...">. The connection
stays open and each new boundary part replaces the previous frame in-place
— no JavaScript decoder needed. Perfect for streaming face-animation frames
from a Python service to the browser.
"""
import asyncio
from typing import AsyncIterator

from starlette.responses import StreamingResponse

BOUNDARY = "frameboundary"


async def _multipart_stream(frames: AsyncIterator[bytes]) -> AsyncIterator[bytes]:
    """Wrap each JPEG payload in a multipart part with the right headers."""
    async for jpeg in frames:
        yield (
            f"--{BOUNDARY}\r\n"
            f"Content-Type: image/jpeg\r\n"
            f"Content-Length: {len(jpeg)}\r\n\r\n"
        ).encode()
        yield jpeg
        yield b"\r\n"


def mjpeg_response(frames: AsyncIterator[bytes]) -> StreamingResponse:
    return StreamingResponse(
        _multipart_stream(frames),
        media_type=f"multipart/x-mixed-replace; boundary={BOUNDARY}",
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Connection": "close",
        },
    )
