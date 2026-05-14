import multiprocessing

from pydantic_settings import BaseSettings, SettingsConfigDict


def _detect_device() -> str:
    """GPU first, CPU fallback — checked once at startup."""
    try:
        import ctranslate2
        if ctranslate2.get_cuda_device_count() > 0:
            return "cuda"
        return "cpu"
    except Exception:
        pass
    try:
        import torch
        if torch.cuda.is_available():
            return "cuda"
    except Exception:
        pass
    return "cpu"


DEVICE: str = _detect_device()
print(f"[Device] Using: {DEVICE.upper()}")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Server ────────────────────────────────────────────────────────────────
    HOST: str = "0.0.0.0"
    PORT: int = 8004

    # ── Audio ─────────────────────────────────────────────────────────────────
    SAMPLE_RATE: int = 16000

    # ── GPU Models (used when DEVICE=cuda) ────────────────────────────────────
    GPU_MODEL_SW_NORMAL: str = "large-v3"
    GPU_MODEL_EN_NORMAL: str = "large-v3"
    GPU_MODEL_SHED:      str = "medium"

    # ── CPU Models (used when DEVICE=cpu) ─────────────────────────────────────
    CPU_MODEL_SW_NORMAL: str = "small"
    CPU_MODEL_EN_NORMAL: str = "small"
    CPU_MODEL_SHED:      str = "tiny"

    CPU_THREADS_PER_MODEL: int = 4

    # ── Concurrency ───────────────────────────────────────────────────────────
    MAX_CONCURRENT_INFERENCES: int = multiprocessing.cpu_count() * 2

    # ── CPU load thresholds (%) ───────────────────────────────────────────────
    CPU_NORMAL:  float = 70.0
    CPU_REDUCED: float = 85.0
    CPU_SHED:    float = 95.0

    # ── GPU VRAM thresholds (%) ───────────────────────────────────────────────
    GPU_VRAM_NORMAL:  float = 70.0
    GPU_VRAM_REDUCED: float = 85.0
    GPU_VRAM_SHED:    float = 95.0

    # ── Language ──────────────────────────────────────────────────────────────
    SUPPORTED_LANGUAGES: set = {"sw", "en"}

    # ── Derived (not from .env) ────────────────────────────────────────────────
    @property
    def DEVICE(self) -> str:
        return DEVICE

    @property
    def IS_GPU(self) -> bool:
        return DEVICE == "cuda"

    @property
    def COMPUTE_TYPE(self) -> str:
        return "float16" if self.IS_GPU else "int8"

    @property
    def MODEL_SW_NORMAL(self) -> str:
        return self.GPU_MODEL_SW_NORMAL if self.IS_GPU else self.CPU_MODEL_SW_NORMAL

    @property
    def MODEL_EN_NORMAL(self) -> str:
        return self.GPU_MODEL_EN_NORMAL if self.IS_GPU else self.CPU_MODEL_EN_NORMAL

    @property
    def MODEL_SHED(self) -> str:
        return self.GPU_MODEL_SHED if self.IS_GPU else self.CPU_MODEL_SHED

    @property
    def POOL_SIZE(self) -> int:
        if self.IS_GPU:
            return 1
        return max(1, multiprocessing.cpu_count() // self.CPU_THREADS_PER_MODEL)

    @property
    def INFERENCE_PROFILES(self) -> dict:
        if self.IS_GPU:
            return {
                "normal":  {"beam_size": 5, "best_of": 5},
                "reduced": {"beam_size": 3, "best_of": 3},
                "shed":    {"beam_size": 2, "best_of": 2},
            }
        return {
            "normal":  {"beam_size": 3, "best_of": 3},
            "reduced": {"beam_size": 2, "best_of": 2},
            "shed":    {"beam_size": 2, "best_of": 1},
        }


settings = Settings()
