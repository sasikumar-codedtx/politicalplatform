"""
Mock face-animation pipeline.

This file is the *only* thing you replace when you deploy the real
LivePortrait + audio2motion stack on a GPU box. The HTTP layer and the
MJPEG framing don't care what's inside — they just want a bytes iterator
yielding JPEG frames at ~25 fps.

Real-pipeline signature should be exactly this:

    async def render_frames(
        source_jpeg: bytes,        # source face photo bytes
        audio_pcm: np.ndarray,     # int16 mono PCM, ~22 kHz
        sample_rate: int,
    ) -> AsyncIterator[bytes]:
        ...

What the real implementation will do, when you have GPU:
    1. Decode source_jpeg → torch tensor, extract motion latents (LivePortrait
       appearance encoder)
    2. Run audio_pcm through audio2motion model → per-frame motion vectors
       (jaw_open, mouth_shape, brow position, head pose) at 25 fps
    3. For each frame: LivePortrait motion module(appearance, motion_t) →
       RGB frame at native resolution
    4. JPEG-encode each frame, yield bytes

The mock below does (1) "decode photo, (2) "fake motion from audio amplitude
envelope", (3) "draw cartoon mouth over source photo", (4) "encode JPEG".
Wire is the same.
"""
import asyncio
import io
import math
from typing import AsyncIterator

import numpy as np
from PIL import Image, ImageDraw

FRAME_RATE = 25
FRAME_INTERVAL = 1.0 / FRAME_RATE

# Heuristic mouth bbox — replaced by real LivePortrait landmarks in prod.
MOUTH_CX, MOUTH_CY = 0.50, 0.70
MOUTH_W,  MOUTH_H  = 0.22, 0.08


def _amplitude_envelope(pcm: np.ndarray, sample_rate: int, fps: int = FRAME_RATE) -> np.ndarray:
    """RMS amplitude per output frame, scaled 0..1."""
    if pcm.size == 0:
        return np.zeros(0, dtype=np.float32)
    samples_per_frame = max(1, sample_rate // fps)
    n_frames = max(1, len(pcm) // samples_per_frame)
    trimmed = pcm[: n_frames * samples_per_frame].astype(np.float32)
    rms = np.sqrt(np.mean(trimmed.reshape(n_frames, samples_per_frame) ** 2, axis=1))
    rms /= max(rms.max(), 1e-3)
    return np.clip(rms * 1.4, 0.0, 1.0)


def _draw_frame(base: Image.Image, amplitude: float, frame_idx: int) -> bytes:
    """Source photo + cartoon mouth scaled by amplitude → JPEG bytes."""
    img = base.copy()
    draw = ImageDraw.Draw(img)
    W, H = img.size

    # Subtle head sway via slight crop offset
    if amplitude > 0.04:
        cx = int(MOUTH_CX * W)
        cy = int((MOUTH_CY + amplitude * MOUTH_H * 0.15) * H)
        rx = int(MOUTH_W * W * 0.30)
        ry = int(MOUTH_H * H * (0.18 + amplitude * 1.0))
        draw.ellipse(
            (cx - rx, cy - ry, cx + rx, cy + ry),
            fill=(35, 17, 13),
        )

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=82, optimize=False)
    return buf.getvalue()


async def render_frames(source_jpeg: bytes,
                        audio_pcm: np.ndarray,
                        sample_rate: int) -> AsyncIterator[bytes]:
    """Mock LivePortrait+audio2motion: yields JPEG frames at 25 fps that show
    the source photo with a cartoon mouth opening in sync with audio
    amplitude. Replace this whole function with the real GPU pipeline once
    the box is provisioned."""
    base = Image.open(io.BytesIO(source_jpeg)).convert("RGB")
    base.thumbnail((720, 720))           # keep frames small for MJPEG
    envelope = _amplitude_envelope(audio_pcm, sample_rate)

    if envelope.size == 0:
        # No audio — yield ~2 s of idle frames so the client sees the photo
        for _ in range(int(2 * FRAME_RATE)):
            yield _draw_frame(base, 0.0, 0)
            await asyncio.sleep(FRAME_INTERVAL)
        return

    smoothed = 0.0
    for i, target_amp in enumerate(envelope):
        smoothed += (target_amp - smoothed) * 0.45
        yield _draw_frame(base, smoothed, i)
        await asyncio.sleep(FRAME_INTERVAL)


async def render_idle_loop(source_jpeg: bytes) -> AsyncIterator[bytes]:
    """Continuous idle frames — used by the persistent session stream
    between speak() calls. Real implementation should do micro head sway +
    occasional blinks via LivePortrait's idle motion latent."""
    base = Image.open(io.BytesIO(source_jpeg)).convert("RGB")
    base.thumbnail((720, 720))
    while True:
        yield _draw_frame(base, 0.0, 0)
        await asyncio.sleep(FRAME_INTERVAL)
