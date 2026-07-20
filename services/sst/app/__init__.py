from fastapi import FastAPI

from app.api.routes import health, transcribe
from app.core.lifespan import lifespan

app = FastAPI(
    title="STT — Swahili & English",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(health.router)

# Mount transcribe routes TWICE so both work:
#   - bare   /transcribe, /asr        — when the STT service is called directly on :8004
#   - /stt/* prefix                   — when callers reach us through the gateway on :9000
# Without the prefixed mount, gateway requests like /stt/transcribe arrive
# here unchanged and 404 because the route is just /transcribe.
app.include_router(transcribe.router)
app.include_router(transcribe.router, prefix="/stt")
