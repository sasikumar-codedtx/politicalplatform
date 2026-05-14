# gpu-avatar

GPU-side face-animation service. Speaks the HTTP contract the real
LivePortrait + audio2motion stack will use. Right now it runs a **mock
pipeline on CPU** so the rest of the system can be wired and tested
without a GPU. The pipeline is the only file you replace when you deploy
the real stack.

## Phases

| Phase | Backend pipeline | Hardware | Quality |
|---|---|---|---|
| **Now (scaffold)** | `mock_pipeline.py` | Any CPU | Cartoon mouth on a still photo |
| **Real (next)** | LivePortrait + audio2motion | NVIDIA GPU 6 GB+ | Photoreal Vijay actually talking |

## HTTP contract

```
POST   /gpu-svc/sources                  multipart photo   →  { source_id }
GET    /gpu-svc/sources/{id}             JPEG of stored source
DELETE /gpu-svc/sources/{id}

POST   /gpu-svc/sources/{id}/speak       multipart audio   →  { task_id }
GET    /gpu-svc/streams/{task_id}        MJPEG stream (one-shot, consumes task)
GET    /gpu-svc/sources/{id}/idle        MJPEG stream (continuous idle loop)
```

The browser opens `<img src="http://localhost:9000/gpu-svc/streams/<task_id>">`
and receives frames natively via `multipart/x-mixed-replace`. No JavaScript
decoder needed.

## Run

```powershell
# As part of the gateway:
cd D:\codedtx\politicalplatform
python services\run.py        # starts agent + avatar-service + gpu-avatar

# Standalone:
cd services\gpu-avatar
pip install -r requirements.txt
python main.py                # http://localhost:8003
```

Smoke test:

```powershell
# Upload a photo
$result = curl.exe -X POST http://localhost:9000/gpu-svc/sources -F "photo=@vijay.jpg" | ConvertFrom-Json
$srcId  = $result.source_id

# Quick idle stream (open in browser)
start "http://localhost:9000/gpu-svc/sources/$srcId/idle"
```

## Swapping mock → real LivePortrait + audio2motion

Three changes, no other code touches:

1. **GPU box setup** — provision an NVIDIA GPU host (RunPod, on-prem desktop,
   etc.). Clone the LivePortrait repo and an audio2motion implementation:

   ```bash
   git clone https://github.com/KwaiVGI/LivePortrait
   pip install -e LivePortrait
   # audio2motion — choose one based on quality/latency:
   # - https://github.com/yerfor/Real3DPortrait (Real3D-Portrait)
   # - https://github.com/yerfor/GeneFacePlusPlus (GeneFace++)
   # - https://github.com/Doubiiu/CodeTalker (CodeTalker)
   ```

2. **Replace `mock_pipeline.py`** with `real_pipeline.py`. Keep the same two
   coroutine signatures:

   ```python
   FRAME_RATE = 25

   async def render_frames(source_jpeg: bytes,
                           audio_pcm: np.ndarray,
                           sample_rate: int) -> AsyncIterator[bytes]:
       # 1. Load source photo once, extract LivePortrait appearance latent
       # 2. audio_pcm → audio2motion → per-frame motion vectors (25 fps)
       # 3. for each motion vec: LivePortrait(appearance, motion) → RGB frame
       # 4. cv2.imencode('.jpg', frame) → yield bytes

   async def render_idle_loop(source_jpeg: bytes) -> AsyncIterator[bytes]:
       # Same but with tiny random head pose + occasional blinks.
   ```

3. **Point our `avatar-service` (or whichever caller you wire up) at the
   GPU box's URL.** In `.env`:

   ```
   GPU_AVATAR_URL=http://<gpu-host>:8003
   ```

   The gateway already proxies `/gpu-svc/*` to whatever is on `GPU_AVATAR_URL`
   — change one env var, redeploy, done.

## Latency budget (real pipeline, RTX 3060)

| Stage | Time |
|---|---|
| Audio → motion vectors (audio2motion) | ~200 ms / sentence |
| First LivePortrait frame after motion ready | ~150 ms |
| MJPEG transport to browser | ~50 ms |
| **Total to first visible frame** | **~400 ms** + the upstream LLM + TTS latency |

On RTX 4090 the per-frame cost drops to ~25 ms — comfortable 25-30 fps.

## What the mock buys you today

- Verifies the full wire end-to-end (browser ↔ gateway ↔ gpu-avatar)
- Lets you build the web client (`<img src="...gpu-svc/streams/..."`) now
- When the real GPU arrives, the swap is a single file replacement

## Why MJPEG instead of WebRTC

WebRTC would give smoother playback but adds aiortc, STUN/TURN, ICE handling.
For the use case (one viewer per session, low concurrency, simple gateway
proxy), MJPEG is dramatically simpler and the browser renders it natively
inside an `<img>` tag. We can upgrade to WebRTC later if frame-rate matters
more than simplicity.

## Audio: parallel now, muxed later

MJPEG cannot carry audio (it's literally a JPEG sequence). The scaffold
exposes audio as a parallel side-channel:

```
POST /gpu-svc/sources/{id}/speak          → { task_id }
GET  /gpu-svc/streams/{task_id}           → MJPEG video frames
GET  /gpu-svc/streams/{task_id}/audio     → WAV bytes  ← parallel
```

Browser plays both starting at the same sentence trigger; A/V drift is
sub-100 ms for short sentences (good enough for the scaffold).

**For real deployment**, swap to **MPEG-TS muxed** output. The shape:

```python
# real_pipeline.py — replaces mock_pipeline.py
import imageio_ffmpeg, subprocess

async def render_muxed_stream(source_jpeg, audio_pcm, sample_rate):
    # 1. Start FFmpeg subprocess that reads raw RGB on fd0 and raw PCM on fd1
    ffmpeg = subprocess.Popen([
        imageio_ffmpeg.get_ffmpeg_exe(),
        "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "720x720", "-r", "25", "-i", "pipe:0",
        "-f", "s16le", "-ar", str(sample_rate), "-ac", "1", "-i", "pipe:3",
        "-c:v", "h264", "-preset", "ultrafast", "-tune", "zerolatency",
        "-c:a", "aac",
        "-f", "mpegts", "pipe:1",
    ], stdin=PIPE, stdout=PIPE, pass_fds=(3,))

    # 2. Feed LivePortrait frames + audio2motion's audio in parallel
    # 3. Stream FFmpeg's stdout chunks back to caller
    while chunk := ffmpeg.stdout.read(64 * 1024):
        yield chunk
```

Browser side becomes one `<video src="...stream.ts">` with hls.js for older
browsers, or native MSE in Chrome/Edge. No more `<audio>` + `<img>` pair.

FFmpeg ships via `imageio-ffmpeg` (bundled binary, no manual install). Just
add `imageio-ffmpeg` to requirements.txt when you swap to real_pipeline.
