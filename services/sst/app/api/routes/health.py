from fastapi import APIRouter

from app.core.config import settings
from app.services.load_monitor import get_load_level, get_stats

router = APIRouter(tags=["health"])


@router.get("/")
async def root():
    return {
        "service":   "STT",
        "device":    settings.DEVICE,
        "languages": sorted(settings.SUPPORTED_LANGUAGES),
        "asr":       f"http://<host>:{settings.PORT}/asr",
        "health":    f"http://<host>:{settings.PORT}/health",
    }


@router.get("/health")
async def health():
    return {
        "status":              "ok",
        "load_level":          get_load_level(),
        "supported_languages": sorted(settings.SUPPORTED_LANGUAGES),
        **get_stats(),
    }
