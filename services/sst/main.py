"""
Entry point — run with:  python main.py
"""

import uvicorn

from app.core.config import settings

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host=settings.HOST,
        port=settings.PORT,
        ws_max_size=65536 * 1024,  # 1 MB — big headroom for audio chunks
        log_level="info",
        workers=1,                 # single process; model pool handles concurrency
    )
