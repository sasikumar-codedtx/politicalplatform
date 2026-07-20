"""
Load monitor — GPU VRAM when on CUDA, CPU percent when on CPU.
Exposes a single load level string consumed by the inference layer.
"""

import asyncio

import psutil

from app.core.config import settings

# ── GPU VRAM monitoring (pynvml) ──────────────────────────────────────────────
_nvml_handle = None

if settings.IS_GPU:
    try:
        import pynvml
        pynvml.nvmlInit()
        _nvml_handle = pynvml.nvmlDeviceGetHandleByIndex(0)
        print("[Load] NVML initialised — monitoring GPU VRAM.")
    except Exception as e:
        print(f"[Load] pynvml not available ({e}). Falling back to CPU monitoring.")


def _gpu_vram_percent() -> float:
    if _nvml_handle is None:
        return 0.0
    try:
        import pynvml
        mem = pynvml.nvmlDeviceGetMemoryInfo(_nvml_handle)
        return mem.used / mem.total * 100
    except Exception:
        return 0.0


def _gpu_vram_mb() -> dict:
    if _nvml_handle is None:
        return {"used_mb": 0, "total_mb": 0}
    try:
        import pynvml
        mem = pynvml.nvmlDeviceGetMemoryInfo(_nvml_handle)
        return {
            "used_mb":  round(mem.used  / 1024 ** 2),
            "total_mb": round(mem.total / 1024 ** 2),
        }
    except Exception:
        return {"used_mb": 0, "total_mb": 0}


# ── Shared state ──────────────────────────────────────────────────────────────
_current_level: str   = "normal"
_POLL_INTERVAL_S: int = 10


def get_load_level() -> str:
    """Return 'normal' | 'reduced' | 'shed' | 'overload'."""
    return _current_level


def get_stats() -> dict:
    """Return device-specific stats for the /health endpoint."""
    if settings.IS_GPU:
        vram = _gpu_vram_mb()
        return {
            "device":        "cuda",
            "vram_used_mb":  vram["used_mb"],
            "vram_total_mb": vram["total_mb"],
            "vram_pct":      round(_gpu_vram_percent(), 1),
            "cpu_percent":   round(psutil.cpu_percent(), 1),
        }
    return {
        "device":      "cpu",
        "cpu_percent": round(psutil.cpu_percent(), 1),
    }


# ── Background monitor loop ───────────────────────────────────────────────────

async def monitor_loop():
    """Re-evaluates load level every 10 s using GPU VRAM or CPU percent."""
    global _current_level

    while True:
        await asyncio.sleep(_POLL_INTERVAL_S)
        loop = asyncio.get_event_loop()

        if settings.IS_GPU:
            usage = await loop.run_in_executor(None, _gpu_vram_percent)
            normal_t  = settings.GPU_VRAM_NORMAL
            reduced_t = settings.GPU_VRAM_REDUCED
            shed_t    = settings.GPU_VRAM_SHED
            label     = "VRAM"
        else:
            usage = await loop.run_in_executor(None, psutil.cpu_percent, 1)
            normal_t  = settings.CPU_NORMAL
            reduced_t = settings.CPU_REDUCED
            shed_t    = settings.CPU_SHED
            label     = "CPU"

        if usage < normal_t:
            level = "normal"
        elif usage < reduced_t:
            level = "reduced"
        elif usage < shed_t:
            level = "shed"
        else:
            level = "overload"

        if level != _current_level:
            print(f"[Load] {label} {usage:.1f}%  →  {_current_level} → {level}")
            _current_level = level
