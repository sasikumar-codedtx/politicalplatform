from fastapi import FastAPI

from app.api.routes import health, transcribe
from app.core.lifespan import lifespan

app = FastAPI(
    title="STT — Swahili & English",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(health.router)
app.include_router(transcribe.router)   # POST /asr  +  POST /transcribe
