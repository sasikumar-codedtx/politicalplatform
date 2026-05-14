# web-avatar — Realtime 3D Avatar Client

Streams chat with the existing `services/agent` backend and renders a 3D
avatar that lip-syncs to live TTS audio.

## How it works

```
WebSocket  ws://localhost:8001/ws/chat
   │
   ├── token frames    →  live caption + transcript bubble
   ├── audio frames    →  SentenceAudioPlayer queues + plays MP3 blobs
   │                       │
   │                       ▼
   │                  Web Audio AnalyserNode  →  RMS amplitude
   │                                                │
   │                                                ▼
   │                                       morphTargetInfluences[jawOpen]
   │                                       on every SkinnedMesh in the GLB
   └── done frame      →  ends the turn
```

No video. No MP4. The avatar GLB is loaded once and animated entirely in
the browser via amplitude on a single shared AnalyserNode — runs on integrated
GPUs and mid-tier phones at 60fps.

## Setup

```bash
cd services/web-avatar
npm install
npm run dev          # http://localhost:5174
```

The agent backend must be running on `http://localhost:8001`
(`cd services/agent && python main.py`).

## Adding an avatar

Either:
1. **Build one at https://readyplayer.me** → copy the GLB URL → POST it:
   ```bash
   curl -X POST http://localhost:8001/admin/avatars/from-url \
        -H "Content-Type: application/json" \
        -d '{"name":"Vijay","glb_url":"https://models.readyplayer.me/<id>.glb","flavor_id":"tn-tvk"}'
   ```
2. **Upload a photo** (currently stores photo + uses default GLB until
   `PHOTO_TO_AVATAR_API` is configured — see `services/agent/avatar_gen.py`):
   ```bash
   curl -X POST http://localhost:8001/admin/avatars/from-photo \
        -F "name=Vijay" -F "flavor_id=tn-tvk" -F "photo=@vijay.jpg"
   ```

The avatar dropdown in the right panel auto-loads from `GET /admin/avatars`.

## Environment

```env
VITE_API_BASE=http://localhost:8001
VITE_WS_URL=ws://localhost:8001/ws/chat
```

## Customising

- **Lip sync intensity:** `src/AvatarCanvas.jsx` → `target = Math.min(1, raw * 4.5)` — raise the multiplier for more open mouth.
- **Different rigs:** `MOUTH_TARGETS` array in `AvatarCanvas.jsx` — add any blendshape name your GLB exposes (`mouthOpen`, `viseme_O`, etc.).
- **Phoneme-accurate sync (future):** server emits `{type:"viseme", t, v}` frames alongside audio; replace `player.amplitude()` with a viseme timeline lookup in `useFrame`.

## Folder structure

```
services/
├── agent/                      # existing FastAPI backend (extended)
│   ├── streaming.py            # async Ollama streaming + sentence buffer
│   ├── tts.py                  # edge-tts (English / Tamil / Hindi)
│   ├── avatar_gen.py           # photo / URL → cached GLB
│   ├── data/                   # cached GLBs + uploaded photos (runtime)
│   │   ├── avatars/<id>.glb
│   │   └── photos/<id>.jpg
│   └── main.py                 # /ws/chat, /admin/avatars/*, /avatar/{id}.glb
│
└── web-avatar/                 # this folder
    ├── package.json
    ├── vite.config.js
    ├── index.html
    └── src/
        ├── main.jsx
        ├── App.jsx
        ├── AvatarCanvas.jsx    # @react-three/fiber + GLB + lip sync
        ├── useAvatarChat.js    # WebSocket hook
        ├── audio.js            # SentenceAudioPlayer + analyser
        └── styles.css
```

## Flutter integration (same WS protocol)

The mobile app can speak this protocol unchanged. Required packages:

```yaml
dependencies:
  web_socket_channel: ^3.0.1
  flutter_3d_controller: ^2.1.1    # GLB rendering
  just_audio: ^0.9.42               # MP3 streaming
```

Sketch — one WebSocket, two listeners (text + binary), one audio queue:

```dart
final ch = WebSocketChannel.connect(Uri.parse('ws://<host>:8001/ws/chat'));
ch.sink.add(jsonEncode({
  'type': 'user_message', 'session_id': sessionId,
  'message': text, 'flavor_id': 'tn-tvk', 'token': firebaseToken,
}));
ch.stream.listen((data) {
  if (data is String) {
    final msg = jsonDecode(data);
    if (msg['type'] == 'token') captionVM.append(msg['text']);
    if (msg['type'] == 'audio') pendingEnvelope = msg;     // next binary frame
  } else {
    audioQueue.enqueueMp3Bytes(data);                       // plays in order
  }
});
```

For lip sync without a browser, the cleanest path is `flutter_3d_controller`'s
GLB viewer + a periodic amplitude probe from `just_audio` (or a native plugin)
driving a morph target setter on the controller. Same shader / blendshapes as
the web client — only the rendering surface changes.

## Admin UI hook (add an "Avatars" page later)

The avatar endpoints are already live and CORS-open. To add a page in
`services/admin-ui`, the API surface is:

```
GET    /admin/avatars                       → { avatars: [{id, name, glb_url, …}] }
POST   /admin/avatars/from-photo (multipart) → upload photo (multipart: name, flavor_id, photo)
POST   /admin/avatars/from-url   (json)      → { name, glb_url, flavor_id }
DELETE /admin/avatars/{id}                   → delete avatar + photo + GLB
GET    /avatar/{id}.glb                      → static GLB (cached for client)
```

Plug those into a new sidebar entry next to **System Prompt**; the photo upload
matches the existing `/admin/documents/upload` pattern.

## Latency budget

| Stage | Typical |
|---|---|
| First Ollama token | 150–300 ms |
| First sentence flushed early (at comma) | +120–300 ms |
| edge-tts first sentence MP3 | +250–400 ms |
| **First audio plays in browser** | **~600–1000 ms** |

The early-flush trick lives in `streaming.py::_EARLY_FLUSH` — tune it down if
you want faster perceived response at the cost of slightly choppier prosody.

## Swapping the heavy parts

| Component | Default | Swap for |
|---|---|---|
| TTS | edge-tts (cloud, free) | XTTS-v2 streaming (voice cloning) — replace `tts.synthesize_sentence` |
| Avatar gen | placeholder (default GLB) | Ready Player Me partner / Avaturn / MuseTalk — set `PHOTO_TO_AVATAR_API` |
| Lip sync | amplitude RMS | phoneme visemes via `phonemizer` — emit `{type:"viseme"}` frames |
| Rendering | three.js GLB | any GLB viewer — same morph target names |
