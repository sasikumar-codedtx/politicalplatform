# tavus-service

Server-side proxy to the [Tavus](https://tavus.io) Conversational Video
Interface (CVI). Browser opens a 2-way video conversation with a photoreal
replica — the heaviest lifting (face render, voice clone, lipsync, STT,
TTS) happens on Tavus's cloud over WebRTC via Daily.co.

The API key never leaves this service.

## When this service runs

It's gated by `ENABLE_TAVUS=true` AND `TAVUS_API_KEY=<your-key>` in `.env`.
Either missing → gateway logs `DISABLED` and returns 503 for `/tavus-svc/*`.

## Endpoints (browser hits these via the gateway)

```
GET    /tavus-svc/replicas          list stock + your custom replicas
GET    /tavus-svc/personas          list personas
POST   /tavus-svc/conversations     start a CVI session    → { conversation_url, ... }
GET    /tavus-svc/conversations/{id}
DELETE /tavus-svc/conversations/{id}
POST   /tavus-svc/webhook           (Phase 2 — custom LLM mode, stubbed)
```

## Quickstart (5 minutes to seeing a replica talk)

```powershell
# 1. .env — set both
ENABLE_TAVUS=true
TAVUS_API_KEY=<your key from tavus.io>

# 2. boot the gateway
cd D:\codedtx\politicalplatform
python services\run.py

# 3. pick a stock replica id
$replicas = curl http://localhost:9000/tavus-svc/replicas | ConvertFrom-Json
$rid = $replicas.data[0].replica_id

# 4. start a conversation
$body = @{ replica_id = $rid } | ConvertTo-Json
$conv = curl -X POST -H "Content-Type: application/json" -d $body http://localhost:9000/tavus-svc/conversations | ConvertFrom-Json

# 5. open the conversation URL in a browser
start $conv.conversation_url
```

That browser tab is a working two-way conversation with the replica — you
talk, it listens (Tavus STT), thinks (Tavus built-in LLM with our system
prompt), answers with synthesised speech and lip-synced video. No code
on the browser side, no webhook, no GPU on your machine.

## System prompt

Default lives in `main.py` as `DEFAULT_SYSTEM_PROMPT`. Override at runtime
with `TAVUS_SYSTEM_PROMPT` in `.env`. Or pass `system_prompt` in the POST
body of `/tavus-svc/conversations` for a per-session override.

## Phase 1 vs Phase 2

| Aspect | Phase 1 (current) | Phase 2 (later) |
|---|---|---|
| LLM that answers user | Tavus built-in | Our agent (Ollama + RAG) |
| Setup complexity | API key only | API key + public URL + ngrok/Cloudflare |
| RAG access | No | Yes |
| Persona prompt | Sent inline as `conversational_context` | Same |
| Tavus calls our server? | No | Yes, on every user turn |

Switching to Phase 2 is two changes: implement the `/tavus-svc/webhook`
body (forward to agent's `/chat`, return the reply), and set
`custom_llm_url` when creating conversations.

## Cloning Vijay's voice (personal replica training)

In Tavus, **voice cloning and face cloning happen together** — both come
from one training video. There's no separate "voice only" path for CVI.

### Inputs that work

- **1–2 minutes** of Vijay talking to camera
- **720p+** resolution
- **Clean audio** — no crowd, no overlapping voices, no background music
- **Single speaker** — Vijay alone on screen
- **HTTPS-reachable URL** Tavus can download from (S3, Cloudinary,
  CloudFront, public Google Drive direct link, public YouTube via
  third-party downloaders, etc.)

### Two ways to start training

**A. Dashboard (no code)** — open https://platform.tavus.io → Create
Replica → Personal Replica → upload video → wait ~30-60 min → copy the
`replica_id`. Use it directly in `POST /tavus-svc/conversations`.

**B. API (via our service)** —

```powershell
$body = @{
  train_video_url = "https://your-cdn.com/vijay-training.mp4"
  replica_name    = "Vijay TVK Personal"
} | ConvertTo-Json

# kick off training
$result = curl -X POST -H "Content-Type: application/json" -d $body `
          http://localhost:9000/tavus-svc/replicas | ConvertFrom-Json
$result.replica_id   # save this

# poll status — repeat until status = "ready"
curl http://localhost:9000/tavus-svc/replicas/$($result.replica_id)
```

Then use the trained `replica_id` in conversations exactly the same way:

```powershell
$body = @{ replica_id = $result.replica_id } | ConvertTo-Json
$conv = curl -X POST -H "Content-Type: application/json" -d $body `
        http://localhost:9000/tavus-svc/conversations | ConvertFrom-Json
start $conv.conversation_url
```

Now the replica speaks with Vijay's actual cloned voice and shows his face.

### Consent / ToS note

Tavus requires consent from the person whose likeness is being trained.
For a public figure where you don't have explicit permission, this may
violate Tavus's policies — check their terms before deploying to users.
Stock replicas avoid this concern entirely.

## Cost

Tavus free tier covers ~25 minutes of conversation. Paid plans from $39/mo
at time of writing — check https://tavus.io/pricing for current numbers.
The replica training step (custom replica from a Vijay video) is a separate
charge if you go beyond stock replicas.

## Embedding the conversation in our web-avatar UI

Not done yet. The next step is to add a "Tavus" avatar type alongside
"Face Photo" in the admin UI, store its `replica_id` in the avatars table,
and have web-avatar render the `conversation_url` in an `<iframe>` instead
of the canvas. That's a small follow-up — ask when you want it.
