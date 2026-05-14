# Speech-to-Text — Swahili & English

A production-ready STT API built with FastAPI and faster-whisper.
Supports **Swahili (sw)** and **English (en)**, auto-detects GPU and uses it when available,
falls back to CPU automatically. Designed for 1M+ user scale.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [How It Works — Full Flow](#2-how-it-works--full-flow)
3. [Server Startup — Step by Step](#3-server-startup--step-by-step)
4. [API Reference](#4-api-reference)
5. [Environment Variables (.env)](#5-environment-variables-env)
6. [Config (config.py) — Computed Settings](#6-config-configpy--computed-settings)
7. [GPU vs CPU Logic](#7-gpu-vs-cpu-logic)
8. [Concurrency & Scale](#8-concurrency--scale)
9. [Load Shedding](#9-load-shedding)
10. [Installation & Running](#10-installation--running)

---

## 1. Project Structure

```
voice-model/
├── .env                              ← All configuration (edit this)
├── requirements.txt                  ← Python dependencies
├── main.py                           ← Entry point — uvicorn.run()
│
└── app/
    ├── __init__.py                   ← FastAPI app instance + router registration
    │
    ├── core/
    │   ├── config.py                 ← Reads .env, detects GPU/CPU, exposes settings
    │   └── lifespan.py               ← Startup: preload models, start monitor task
    │
    ├── api/
    │   └── routes/
    │       ├── health.py             ← GET /health
    │       └── transcribe.py         ← POST /asr  +  POST /transcribe
    │
    └── services/
        ├── stt_engine.py             ← Model pool, transcribe_file(), detect_language()
        └── load_monitor.py           ← CPU% or GPU VRAM% polling → load level
```

---

## 2. How It Works — Full Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SERVER STARTUP                                 │
│                                                                         │
│  main.py → uvicorn starts FastAPI app                                   │
│          → config.py detects GPU or CPU (once, at import time)          │
│          → lifespan.py preloads Whisper models into memory              │
│          → background task starts:                                      │
│              • load monitor (every 10s — CPU% or GPU VRAM%)             │
└─────────────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER REQUEST                                   │
│                                                                         │
│  Client sends POST /asr or POST /transcribe with audio file             │
│                                                                         │
│  Server:                                                                │
│    1. Validates content-type and file size (max 10 MB)                  │
│    2. Checks load level — overload → use shed model                     │
│    3. Saves temp file → faster-whisper inference → deletes temp file    │
│    4. Returns { text, language, language_probability }                  │
└─────────────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        INFERENCE PIPELINE                               │
│                                                                         │
│  faster-whisper runs in ThreadPoolExecutor (non-blocking)               │
│  Model pool (thread-safe queue) serves concurrent requests              │
│  Load level selects beam_size automatically                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Server Startup — Step by Step

### Step 1 — `main.py`
Calls `uvicorn.run("app:app", host, port, workers=1)`.
Single process — model pool handles all concurrency internally.

### Step 2 — `app/__init__.py`
Creates the FastAPI instance and registers two routers: `health.router` and `transcribe.router`.

### Step 3 — `app/core/config.py` (runs at import time)
- Calls `_detect_device()` — checks CTranslate2 CUDA → torch fallback → CPU
- Sets module-level `DEVICE = "cuda"` or `"cpu"`
- Creates `settings = Settings()` — reads all values from `.env`

### Step 4 — `app/core/lifespan.py` (runs when server starts)
```
1. Creates ThreadPoolExecutor(max_workers=MAX_CONCURRENT_INFERENCES)
   → Runs all blocking Whisper inference off the event loop

2. Calls preload_models() in the executor
   → Downloads models from HuggingFace if not cached (first run only)
   → Loads normal models into RAM (CPU) or VRAM (GPU)
   → Shed model is lazy-loaded on first use (keeps startup fast)

3. Starts monitor_loop() as async background task
   → Runs every 10s
   → GPU: reads VRAM% via pynvml
   → CPU: reads CPU% via psutil
   → Updates global load level: normal / reduced / shed / overload
```

### Step 5 — Server is ready
FastAPI begins accepting requests on `HOST:PORT` (default `0.0.0.0:9000`).

---

## 4. API Reference

### `GET /health`
Returns device info and current load level.

```json
{
  "status":      "ok",
  "load_level":  "normal",
  "device":      "cpu",
  "cpu_percent": 43.2
}
```
On GPU:
```json
{
  "status":        "ok",
  "load_level":    "normal",
  "device":        "cuda",
  "vram_used_mb":  4200,
  "vram_total_mb": 8192,
  "vram_pct":      51.3
}
```

---

### `POST /asr` — Transcribe audio file

Same as `POST /transcribe` — both routes use the same handler for compatibility.

**Request:**
```
Content-Type: multipart/form-data

audio_file   (required) — audio file upload
language     (optional) — "sw" or "en"  (default: "en")
task         (optional) — ignored, for compatibility
```

**Supported audio formats:** wav, mp3, ogg, webm, mp4, m4a, flac

**Limits:** max 10 MB per file

**Response:**
```json
{
  "text": "Habari yako?",
  "language": "sw",
  "language_probability": 0.97
}
```

**On no speech detected:**
```json
{
  "text": "",
  "language": "sw",
  "language_probability": 0.0,
  "error": "No speech detected in audio."
}
```

**Example (curl):**
```bash
curl -X POST http://localhost:9000/asr \
  -F "audio_file=@recording.webm" \
  -F "language=sw"
```

**Example (Python):**
```python
import requests

with open("recording.webm", "rb") as f:
    r = requests.post(
        "http://localhost:9000/asr",
        files={"audio_file": f},
        params={"language": "sw"},
    )
print(r.json())
# {'text': 'Habari yako?', 'language': 'sw', 'language_probability': 0.97}
```

---

## 5. Environment Variables (.env)

### SERVER

| Variable | Default | Explanation |
|---|---|---|
| `HOST` | `0.0.0.0` | Interface to bind. Use `127.0.0.1` for localhost only. |
| `PORT` | `9000` | Port the server listens on. |

### GPU MODELS (used when CUDA is detected)

| Variable | Default | Explanation |
|---|---|---|
| `GPU_MODEL_SW_NORMAL` | `large-v3` | Whisper model for Swahili on GPU. Best Swahili accuracy. |
| `GPU_MODEL_EN_NORMAL` | `large-v3` | Whisper model for English on GPU. |
| `GPU_MODEL_SHED` | `medium` | Fallback when GPU VRAM exceeds threshold. |

### CPU MODELS (used when no GPU is detected)

| Variable | Default | Explanation |
|---|---|---|
| `CPU_MODEL_SW_NORMAL` | `small` | Whisper model for Swahili on CPU. |
| `CPU_MODEL_EN_NORMAL` | `small` | Whisper model for English on CPU. |
| `CPU_MODEL_SHED` | `tiny` | Fallback when CPU load exceeds threshold. |
| `CPU_THREADS_PER_MODEL` | `4` | CPU threads each model instance uses internally. |

### CONCURRENCY

| Variable | Default | Explanation |
|---|---|---|
| `MAX_CONCURRENT_INFERENCES` | `cpu_cores × 2` | Max simultaneous Whisper inferences. Requests wait in queue when limit is hit. |

### GPU VRAM THRESHOLDS

| Variable | Default | Explanation |
|---|---|---|
| `GPU_VRAM_NORMAL` | `70` | Below this %: full quality (beam=5). |
| `GPU_VRAM_REDUCED` | `85` | Reduced quality (beam=3). |
| `GPU_VRAM_SHED` | `95` | Shed model (beam=2). Above this: overload — use shed model. |

### CPU LOAD THRESHOLDS

| Variable | Default | Explanation |
|---|---|---|
| `CPU_NORMAL` | `70` | Below this %: full quality (beam=3). |
| `CPU_REDUCED` | `85` | Reduced quality (beam=2). |
| `CPU_SHED` | `95` | Shed model (beam=2). Above this: overload — use shed model. |

### AUDIO

| Variable | Default | Explanation |
|---|---|---|
| `SAMPLE_RATE` | `16000` | Whisper requires 16kHz. Do not change. |

---

## 6. Config (config.py) — Computed Settings

`config.py` reads `.env` and exposes computed properties used by the services.

### Device Detection (runs once at import)

1. Tries `ctranslate2.get_cuda_device_count()` (native CTranslate2 CUDA check)
2. Falls back to `torch.cuda.is_available()`
3. Falls back to `"cpu"`

### Computed Properties

| Property | Returns | Why |
|---|---|---|
| `settings.DEVICE` | `"cuda"` or `"cpu"` | Passed to WhisperModel |
| `settings.IS_GPU` | `True` / `False` | Shorthand used throughout |
| `settings.COMPUTE_TYPE` | `"float16"` (GPU) or `"int8"` (CPU) | float16 = full GPU precision; int8 = quantized for CPU speed |
| `settings.MODEL_SW_NORMAL` | Model name | Switches between GPU_MODEL_* and CPU_MODEL_* automatically |
| `settings.MODEL_EN_NORMAL` | Model name | Same |
| `settings.MODEL_SHED` | Model name | Same |
| `settings.POOL_SIZE` | `1` (GPU) or `cpu_count/cpu_threads` (CPU) | GPU: 1 instance + internal workers. CPU: multiple instances |
| `settings.INFERENCE_PROFILES` | Dict of beam_size per level | GPU: 5/3/2. CPU: 3/2/2 |

---

## 7. GPU vs CPU Logic

```
At startup, _detect_device() runs:

  CTranslate2 CUDA available?
    YES → DEVICE = "cuda"
          COMPUTE_TYPE = "float16"
          POOL_SIZE = 1  (one model, internal num_workers handles concurrency)
          Models: GPU_MODEL_SW_NORMAL / GPU_MODEL_EN_NORMAL (default: large-v3)
          Beam size: 5 (normal), 3 (reduced), 2 (shed)
          Monitor: GPU VRAM % via pynvml

    NO  → DEVICE = "cpu"
          COMPUTE_TYPE = "int8"
          POOL_SIZE = cpu_count / CPU_THREADS_PER_MODEL
          Models: CPU_MODEL_SW_NORMAL / CPU_MODEL_EN_NORMAL (default: small)
          Beam size: 3 (normal), 2 (reduced), 2 (shed)
          Monitor: CPU % via psutil
```

---

## 8. Concurrency & Scale

```
1 server process (uvicorn, single worker)
  │
  ├── asyncio event loop
  │     Handles all HTTP I/O — non-blocking
  │
  └── ThreadPoolExecutor (MAX_CONCURRENT_INFERENCES threads)
        Handles all Whisper inference — blocking, off event loop

  Model pool (thread-safe queue of WhisperModel instances)
    → Each request acquires a model, runs inference, returns it to pool
    → Requests wait in executor queue when all models are busy
```

**Scale beyond one server:** Run multiple instances behind a load balancer.
Each is fully stateless — no sessions, no shared memory.

---

## 9. Load Shedding

The load monitor runs every 10 seconds. Inference quality adjusts automatically:

| Level | GPU (VRAM) | CPU | Model | Beam Size |
|---|---|---|---|---|
| `normal` | < 70% | < 70% | large-v3 / small | 5 / 3 |
| `reduced` | 70–85% | 70–85% | large-v3 / small | 3 / 2 |
| `shed` | 85–95% | 85–95% | medium / tiny | 2 / 2 |
| `overload` | > 95% | > 95% | tiny (shed) | 2 |

At `overload`, the shed model is used instead of rejecting requests.

---

## 10. Installation & Running

### Requirements
- Python 3.10+
- CUDA toolkit (optional, for GPU support)

### Install
```bash
pip install -r requirements.txt
```

### Run
```bash
python main.py
```

Server starts on `http://0.0.0.0:9000`. Startup output:
```
[Device] Using: CPU
[STT] Loading 2× 'small' on CPU (int8) …
[STT]   small instance 1/2 ready
[STT]   small instance 2/2 ready
[STT] Normal models ready on CPU. Shed model loads on first use.
[App] Ready — http://0.0.0.0:9000/asr
```

### Override models via environment
```bash
# Use fine-tuned Swahili model on CPU
CPU_MODEL_SW_NORMAL=mbazaNLP/whisper-medium-sw python main.py

# Use medium on GPU for lower VRAM usage
GPU_MODEL_SW_NORMAL=medium GPU_MODEL_EN_NORMAL=medium python main.py
```

### Health check
```bash
curl http://localhost:9000/health
```

### Quick test
```bash
curl -X POST http://localhost:9000/asr \
  -F "audio_file=@recording.webm" \
  -F "language=sw"
```
