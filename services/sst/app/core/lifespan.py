import asyncio
from contextlib import asynccontextmanager
from concurrent.futures import ThreadPoolExecutor

from fastapi import FastAPI

from app.core.config import settings
from app.services.stt_engine import preload_models
from app.services.load_monitor import monitor_loop


# Shared executor — imported by transcribe route and services
executor = ThreadPoolExecutor(max_workers=settings.MAX_CONCURRENT_INFERENCES)


@asynccontextmanager
async def lifespan(app: FastAPI):
    loop = asyncio.get_event_loop()

    print("[App] Pre-loading STT models …")
    await loop.run_in_executor(executor, preload_models)

    asyncio.create_task(monitor_loop())

    print(f"[App] Ready — http://{settings.HOST}:{settings.PORT}/asr")
    yield

    executor.shutdown(wait=False)
