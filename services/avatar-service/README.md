# avatar-service

Self-hosted avatar pipeline. Runs on port 8002 alongside the existing `agent`
service on port 8001. Boot both together with `python services/run.py`.

## Status

**MVP1 (current):** photo upload + Piper TTS synthesis. Browser shows the photo
as a plain `<img>` and plays per-sentence WAV via the existing audio queue.

**MVP2 (next):** WebRTC video track with 2D mouth-mask animation driven by
audio amplitude.

**MVP3:** idle blinks + OpenVoice offline voice cloning.

## Endpoints

```
POST   /avatars/photo                multipart: photo, voice_id    → { avatar_id, photo_url, voice_id }
GET    /avatars/{id}/photo                                          → image bytes
POST   /session/{id}/speak           { text, voice_id? }            → audio/wav bytes
DELETE /avatars/{id}                                                → cleanup
GET    /                                                            → status
```

## Setup

```powershell
cd services\avatar-service
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

First run will download the default Piper voice (`en_US-amy-medium`, ~60 MB)
from `huggingface.co/rhasspy/piper-voices`. If that domain is blocked on your
network:

```powershell
# Pre-place the files manually:
mkdir models
# Drop en_US-amy-medium.onnx and en_US-amy-medium.onnx.json into models/
```

## Voice ids

Bundled (auto-download from rhasspy/piper-voices on HuggingFace):
- `en_US-amy-medium` — neutral US English female (default)
- `en_US-ryan-medium` — US English male
- `en_GB-alan-medium` — British English male
- `hi_IN-priyamvada-medium` — Hindi female

For Tamil, drop any `.onnx` + `.onnx.json` pair into `models/` and reference
by the file stem.
