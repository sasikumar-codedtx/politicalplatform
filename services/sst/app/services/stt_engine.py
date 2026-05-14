"""
Model pool + inference logic.
GPU is used automatically when available; falls back to CPU.
All public functions are synchronous — call them via ThreadPoolExecutor.
"""

import queue
import threading
from contextlib import contextmanager

import numpy as np
from faster_whisper import WhisperModel

from app.core.config import settings

# ── Model Pool ────────────────────────────────────────────────────────────────

class _ModelPool:
    """Thread-safe pool of WhisperModel instances."""

    def __init__(self, model_id: str, pool_size: int):
        self._q: queue.Queue[WhisperModel] = queue.Queue()
        device       = settings.DEVICE
        compute_type = settings.COMPUTE_TYPE

        print(f"[STT] Loading {pool_size}× '{model_id}' on {device.upper()} ({compute_type}) …")

        for i in range(pool_size):
            kwargs = dict(
                device=device,
                compute_type=compute_type,
                num_workers=settings.MAX_CONCURRENT_INFERENCES if settings.IS_GPU else 1,
            )
            # cpu_threads only applies on CPU
            if not settings.IS_GPU:
                kwargs["cpu_threads"] = settings.CPU_THREADS_PER_MODEL

            model = WhisperModel(model_id, **kwargs)
            self._q.put(model)
            print(f"[STT]   {model_id}  instance {i + 1}/{pool_size} ready")

    @contextmanager
    def acquire(self):
        model = self._q.get()
        try:
            yield model
        finally:
            self._q.put(model)


_pools: dict[str, _ModelPool] = {}
_pool_lock = threading.Lock()


def _get_pool(model_id: str) -> _ModelPool:
    if model_id not in _pools:
        with _pool_lock:
            if model_id not in _pools:
                _pools[model_id] = _ModelPool(model_id, settings.POOL_SIZE)
    return _pools[model_id]


def preload_models():
    """
    Warm only the normal-quality models at startup.
    The shed (fallback) model is lazy-loaded on first use to keep startup fast.
    """
    for model_id in {settings.MODEL_SW_NORMAL, settings.MODEL_EN_NORMAL}:
        _get_pool(model_id)
    print(f"[STT] Normal models ready on {settings.DEVICE.upper()}. Shed model loads on first use.")


# ── Inference ─────────────────────────────────────────────────────────────────

def _model_id_for(lang: str, load_level: str) -> str:
    if load_level == "shed":
        return settings.MODEL_SHED
    return settings.MODEL_SW_NORMAL if lang == "sw" else settings.MODEL_EN_NORMAL


def transcribe(
    audio: np.ndarray,
    lang: str,
    load_level: str = "normal",
    prev_text: str = "",
) -> dict:
    """Blocking transcription. Returns { text, words, detected_lang, lang_prob }."""
    model_id = _model_id_for(lang, load_level)
    profile  = settings.INFERENCE_PROFILES[load_level]

    with _get_pool(model_id).acquire() as model:
        segments, info = model.transcribe(
            audio,
            language=lang,
            beam_size=profile["beam_size"],
            best_of=profile.get("best_of", 1),
            vad_filter=True,
            vad_parameters={
                "min_silence_duration_ms": 400,
                "min_speech_duration_ms":  200,
            },
            word_timestamps=True,
            condition_on_previous_text=bool(prev_text),
            initial_prompt=prev_text or None,
        )

        text_parts: list[str] = []
        words: list[dict]     = []
        for seg in segments:
            if seg.text.strip():
                text_parts.append(seg.text.strip())
            if seg.words:
                words.extend(
                    {"word": w.word, "start": w.start, "end": w.end}
                    for w in seg.words
                )

    return {
        "text":          " ".join(text_parts).strip(),
        "words":         words,
        "detected_lang": info.language,
        "lang_prob":     round(info.language_probability, 3),
    }


def transcribe_file(
    file_path: str,
    lang: str,
    load_level: str = "normal",
    initial_prompt: str = "",
) -> dict:
    """
    Blocking transcription from an audio file path.
    faster-whisper accepts file paths directly — no numpy conversion needed.
    Returns { text, language, language_probability }.
    """
    model_id = _model_id_for(lang, load_level)
    profile  = settings.INFERENCE_PROFILES[load_level]

    with _get_pool(model_id).acquire() as model:
        segments, info = model.transcribe(
            file_path,
            language=lang,
            beam_size=profile["beam_size"],
            best_of=profile.get("best_of", 1),
            vad_filter=True,
            vad_parameters={
                "min_silence_duration_ms": 400,
                "min_speech_duration_ms":  200,
            },
            word_timestamps=False,
            initial_prompt=initial_prompt or None,
        )
        text_parts = [seg.text.strip() for seg in segments if seg.text.strip()]

    return {
        "text":                 " ".join(text_parts).strip(),
        "language":             info.language if info.language else lang,
        "language_probability": round(info.language_probability, 3),
    }


def detect_language(audio: np.ndarray) -> tuple[str, float]:
    """Auto-detect language. Blocking. Falls back to 'en' if unsupported."""
    with _get_pool(settings.MODEL_EN_NORMAL).acquire() as model:
        _, info = model.transcribe(audio, beam_size=1, language=None, vad_filter=True)

    lang = info.language if info.language in settings.SUPPORTED_LANGUAGES else "en"
    return lang, round(info.language_probability, 3)
