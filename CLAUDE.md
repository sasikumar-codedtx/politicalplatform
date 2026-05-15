# Political Platform — Project Knowledge Base

> This file is the single source of truth for this project.
> It is read by Claude Code at the start of every session.
> Read order: this file → `TEAM_WORKFLOW.md` → `ROADMAP.md` before touching code.
> `ROADMAP.md` contains the full architecture, DB schema, RAG plan, and phase-by-phase build plan.
> Update the Changelog at the end of every session before closing.

---

## What This Project Is

A multi-client political AI agent platform. Citizens can talk to their political leader via an AI agent. Built to scale to 5 crore users. Supports Tamil and English.

**First client:** `india-pm` flavour (see client mapping in memory).

**5 planned modules:**

1. CM AI Agent (chat with political leader)
2. Citizen Services (Vahan / Sarathi integrations)
3. Community & Project Platform
4. News Hub
5. Five-Year Governance Roadmap

---

## Repo

`git@github.com:sasikumar-codedtx/politicalplatform.git`

---

## Project Structure

```
political-platform/
├── services/
│   └── agent/              # FastAPI backend
│       ├── main.py         # API routes
│       ├── agent.py        # Session + Ollama calls
│       ├── persona.py      # AI character definition
│       ├── requirements.txt
│       └── Dockerfile
├── mobile/
│   └── app/                # Flutter iOS + Android app
│       ├── lib/
│       │   ├── main.dart
│       │   ├── config/
│       │   │   └── app_config.dart       # Flavour + API URL
│       │   ├── models/
│       │   │   └── chat_session.dart     # ChatSession, ChatMessage
│       │   ├── screens/
│       │   │   ├── phone_login_screen.dart
│       │   │   ├── dashboard_screen.dart
│       │   │   └── chat_screen.dart
│       │   └── services/
│       │       ├── agent_service.dart    # HTTP calls to backend
│       │       └── chat_storage.dart     # SharedPreferences
│       └── ios/
│           └── Runner/
│               ├── GoogleService-Info.plist   # Bundle ID: com.codedtx.politicalPlatform
│               └── Info.plist
├── docker-compose.yml
├── .env
└── CLAUDE.md               # ← this file
```

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Mobile | Flutter 3.x | iOS + Android, MVVM pattern |
| Auth | Firebase Phone OTP | iOS 15.0 minimum |
| Backend | FastAPI (Python 3.12) | Port 8001 |
| AI | Ollama llama3.2 | Local, port 11434 |
| Storage (now) | SharedPreferences | Temporary, phone-local only |
| Storage (next) | PostgreSQL + pgvector | For RAG + user profiles |
| Cache (next) | Redis | Sessions, rate limiting |
| Voice (next) | Sarvam AI STT + Coqui XTTS | Tamil speech |
| Deploy (next) | AWS ECS Fargate | ap-south-1 Mumbai |

---

## Local Dev Setup

### Run backend

```bash
conda activate political-agent
cd services/agent
python main.py
# FastAPI runs on http://localhost:8001
```

### Run Ollama

```bash
ollama serve
# Runs on http://localhost:11434
```

### Run Flutter

```bash
cd mobile/app
flutter run
```

### Pod install (iOS)

```bash
export LANG=en_US.UTF-8
cd mobile/app/ios
pod install
```

### API URL

Hardcoded LAN IP in `mobile/app/lib/config/app_config.dart`.
Run `ipconfig getifaddr en0` to get current IP and update if changed.

---

## Architecture — Flutter (MVVM)

All new Flutter code must follow MVVM:

```
View (screens/)        → UI only, no business logic
ViewModel (viewmodels/)→ state, logic, calls services
Service (services/)    → API calls, storage, Firebase
Model (models/)        → pure data classes, JSON serialization
```

Current screens were built before MVVM was adopted. Migrate gradually — do not refactor working screens unless the task requires it.

---

## What Is Built

### Auth

- Firebase Phone OTP (iOS + Android)
- `appVerificationDisabledForTesting` correctly skipped on physical devices
- Firebase ID token sent as `Authorization: Bearer` on every API call
- Backend accepts token but does **not** verify it yet (open for now)

### Mobile

- Login screen → phone number → OTP → dashboard
- Dashboard → list of past sessions (local), swipe to delete, new chat FAB
- Chat screen → message bubbles, animated thinking dots, auto-scroll
- Local persistence via SharedPreferences (sessions + messages)
- Flavour system — `india-pm` flavour with Indian flag green/saffron theme

### Backend

- `POST /chat` — send message, get AI reply
- `GET /history/{session_id}` — get past messages
- `DELETE /session/{session_id}` — clear session
- In-memory session store (wiped on restart)
- Persona: CM of Tamil Nadu, Tamil/English bilingual, 3–5 sentence replies

---

## What Is NOT Built Yet (Ordered by Priority)

1. **APNs key** — real device OTP without 5s fallback delay
2. **Dynamic API URL** — LAN IP breaks on network change
3. **Backend auth** — firebase-admin token verification → our JWT → user profiles
4. **PostgreSQL** — persistent chat history, user data
5. **pgvector + RAG** — feed real policies/schemes to the AI
6. **User profiles + KYC** — name, constituency, ID verification
7. **MVVM migration** — move existing screens to proper ViewModel pattern
8. **Voice** — Sarvam AI STT + Coqui XTTS for Tamil
9. **Redis** — session cache, rate limiting
10. **Docker Compose full stack** — DB + Redis + agent
11. **AWS ECS deploy** — production

---

## Coding Rules

These rules are non-negotiable. Every session must follow them.

### Shared assistant workflow

- Codex and Claude must both follow `TEAM_WORKFLOW.md`
- When touching code, always log the reason and verification there
- Keep `TEAM_WORKFLOW.md`, `AGENTS.md`, and `CLAUDE.md` aligned if workflow rules change

### 1. Never break existing functionality

- Test what is working before changing anything near it
- If a change touches a working feature, explicitly verify it still works after

### 2. Step by step — no mass changes

- One feature or fix per session
- Each change must be small enough to review and revert independently
- Never refactor and add features at the same time

### 3. Flutter MVVM — strictly

- Screens contain only UI (widgets, animations)
- Business logic lives in ViewModels
- API/storage calls live in Services
- No `http` calls or `SharedPreferences` access directly inside a screen

### 4. No over-engineering

- Build exactly what is needed, nothing more
- No abstractions for hypothetical future requirements
- Three similar lines is better than a premature abstraction

### 5. No comments that explain what the code does

- Good names make comments redundant
- Only comment WHY something is done if it is non-obvious

### 6. Security

- Never commit secrets (.env, API keys, service account files)
- Never expose real client names in code — use flavour IDs only
- Validate all user input at the boundary (API endpoints, form fields)

### 7. Every session ends with a Changelog entry

- Add a row to the Changelog at the bottom of this file
- Format: `DATE | WHAT CHANGED | FILES TOUCHED`

---

## Firebase

- **Project ID:** `political-platform-19d77`
- **iOS bundle ID:** `com.codedtx.politicalPlatform`
- **Android bundle ID:** (not set up yet)
- **GoogleService-Info.plist:** `mobile/app/ios/Runner/GoogleService-Info.plist`
- **iOS min deployment target:** 15.0 (required by Firebase SDK 12.x)
- **firebase_core:** ^4.7.0
- **firebase_auth:** ^6.4.0

---

## iOS Build Notes

- Always run `export LANG=en_US.UTF-8` before `pod install` (Ruby encoding bug)
- GoogleService-Info.plist bundle ID must exactly match Xcode bundle ID (case-sensitive)
- URL scheme in Info.plist: `app-1-151735878015-ios-56191dd500165368e89a4a`
- APNs not configured yet — real device OTP falls back to reCAPTCHA (5s delay)

---

## Flavour System

| Flavour ID | Primary Colour | App Name |
|---|---|---|
| tn-tvk | #E53935 (red) | TVK |
| india-pm | #19AAED (INC sky blue) | India PM |

Add new flavours in `app_config.dart` only. Never use real client names in code.

---

## Changelog

| Date | What Changed | Files Touched |
|---|---|---|
| 2026-05-07 | Project scaffolded — FastAPI agent + Flutter app with Firebase OTP auth, dashboard, chat | All files |
| 2026-05-07 | Fixed Firebase login on iOS: bundle ID mismatch, iOS min target 15.0, LANG fix for pod install | GoogleService-Info.plist, Podfile, Info.plist, pubspec.yaml |
| 2026-05-07 | Fixed logout spinner — removed broken named route navigation, StreamBuilder handles it | dashboard_screen.dart |
| 2026-05-07 | Firebase upgraded to firebase_core 4.7.0 + firebase_auth 6.4.0 (Firebase SDK 12.x, iOS 26 compat) | pubspec.yaml, Podfile |
| 2026-05-07 | Dynamic LAN IP fix — updated API URL to 192.168.1.37 | app_config.dart |
| 2026-05-07 | Added device_info_plus — correct simulator detection for appVerificationDisabledForTesting | pubspec.yaml, phone_login_screen.dart |
| 2026-05-08 | Full app built — 13 screens across 5 tabs (Home, Chat, News, Services, Profile). Splash + Onboarding. inc.in design cloned. Theme system. Flavor extended with partyName/leaderName/tagline/aiPersona. Primary color corrected to #19AAED | app_config.dart, app_theme.dart, app_assets.dart, main.dart, splash_screen.dart, onboarding_screen.dart, main_shell.dart, home_screen.dart, chat_list_screen.dart, news_screen.dart, issues_screen.dart, leader_screen.dart, manifesto_screen.dart, services_screen.dart, community_screen.dart, profile_screen.dart, pubspec.yaml |
| 2026-05-08 | AI persona moved to flavor config — each brand sends its own system prompt on session init. Backend accepts optional persona field, falls back to DEFAULT_PERSONA. persona.py made generic. | persona.py, agent.py, main.py, agent_service.dart, app_config.dart |
| 2026-05-08 | Full dark-theme rebuild — MVVM pattern, two flavors (tn-tvk + india-pm), mock data via ContentService/PollService, provider added. All screens rebuilt: HomeScreen (hero+news+poll+events+shorts), NewsScreen (search+filter), ManifestoScreen (plans+vision tabs), LeaderScreen (about+milestones+media), EventsScreen, JoinScreen, ShortsScreen, ProfileScreen, ChatListScreen, ChatScreen. MainShell center-FAB dark nav. FlavorConfig extended with dark tokens. | pubspec.yaml, app_config.dart, models/*, services/content_service.dart, services/poll_service.dart, viewmodels/*, screens/* |
| 2026-05-08 | Full light-theme migration — TVK formed govt, app is now Tamil Nadu Government app. All screens converted from dark to light: white AppBars, #F5F5F5 background, #1A1A1A text, no black anywhere. FlavorConfig updated with govtName + textPrimary/textSecondary. New screens: PollsScreen, CommunityScreen (forum posts). Onboarding slides updated to TVK red. Splash gradient updated. Chat bubbles white/red. Input bar white. | app_config.dart, app_theme.dart, main_shell.dart, home_screen.dart, news_screen.dart, events_screen.dart, polls_screen.dart, join_screen.dart, shorts_screen.dart, community_screen.dart, profile_screen.dart, chat_list_screen.dart, chat_screen.dart, manifesto_screen.dart, leader_screen.dart, services_screen.dart, onboarding_screen.dart, splash_screen.dart, issues_screen.dart |
| 2026-05-09 | Full Figma-exact rebuild (dark theme) — all 7 screens rebuilt from get_design_context: pure black bg, Bebas Neue 34px gradient headers, Plus Jakarta Sans body, tvk_flag.png banner, exact measurements. EventsScreen (168px cards, #a23435 gradient, date box), ManifestoScreen (tabs + year timeline + plan cards), LeaderScreen (hero + about/achievements/media tabs), JoinScreen (member details + location + KYC form). Fixed unused variable in home_screen.dart. | events_screen.dart, manifesto_screen.dart, leader_screen.dart, join_screen.dart, home_screen.dart |
| 2026-05-09 | Full detail pages + navigation wiring — 8 new screens: news_detail, event_detail, manifesto_detail, post_detail (with live comments), create_post, create_poll, short_player (full-screen video UI + comments sheet), member_id (ID card + QR + privileges). Navigation wired across all list screens. Zero errors in flutter analyze. | news_detail_screen.dart, event_detail_screen.dart, manifesto_detail_screen.dart, post_detail_screen.dart, create_post_screen.dart, create_poll_screen.dart, short_player_screen.dart, member_id_screen.dart, news_screen.dart, events_screen.dart, manifesto_screen.dart, community_screen.dart, polls_screen.dart, shorts_screen.dart, join_screen.dart, services_screen.dart |
| 2026-05-11 | YouTube integration — TVK channel live stream detection + video grid. YouTubeService (getLiveStream, getUpcomingLive, getRecentVideos, getLiveViewerCount), YouTubeVideo model, secrets.dart (gitignored). HomeScreen _LiveStreamCard shows real thumbnail + Watch Live when live, upcoming card, or offline placeholder. ShortsScreen fetches real channel videos. ShortPlayerScreen uses YoutubePlayerController for in-app playback. iOS Info.plist updated with embedded_views_preview. Zero analyzer errors. | pubspec.yaml, lib/config/secrets.dart, lib/models/youtube_video.dart, lib/services/youtube_service.dart, lib/screens/home_screen.dart, lib/screens/shorts_screen.dart, lib/screens/short_player_screen.dart, ios/Runner/Info.plist |
| 2026-05-11 | YouTube Hub full redesign — switched to LiverpoolFC channel (dynamic handle→ID resolution). YoutubeHubScreen: 4-tab screen (Live/Videos/Shorts/Playlists) with landscape 16:9 cards for videos, portrait 9:16 grid for shorts. ShortsReelScreen: Instagram-style vertical PageView with single YoutubePlayerController, right-side actions. YouTubeService rewritten with _getChannelId() cache + getVideos/getShorts/getPlaylists. YouTubePlaylist model added. HomeScreen "TVK Videos" section shows recent video thumbnail with View All → YoutubeHubScreen. FAB "Videos" → YoutubeHubScreen. Zero analyzer warnings. | secrets.dart, youtube_video.dart, youtube_playlist.dart (new), youtube_service.dart, youtube_hub_screen.dart (new), shorts_reel_screen.dart (new), home_screen.dart, main_shell.dart |
| 2026-05-11 | Clean video player + own like system — VideoPlayerScreen replaces ShortPlayerScreen throughout (no comments, no Google login needed). VideoLikeService persists likes per videoId in SharedPreferences. ShortsReelScreen comment button removed; likes now persisted and loaded per video on swipe. | video_player_screen.dart (new), video_like_service.dart (new), youtube_hub_screen.dart, home_screen.dart, shorts_reel_screen.dart |
| 2026-05-11 | Home shorts + Fan Page — HomeViewModel loads real YouTube shorts (async, non-blocking); TVK Shorts section shows horizontal 9:16 scroll row with View All → YoutubeHubScreen(Shorts tab). Fan Page system: FanPost/FanComment models, FanPostService (SharedPreferences, seeded demo posts), FanPageScreen (Community Wall with All/Popular tabs), MyPostsScreen (My Posts + Admin Panel demo), CreateFanPostScreen, FanPostDetailScreen with own comment system. Community nav tab → FanPageScreen. FAB Post → CreateFanPostScreen. Profile → My Posts row. | home_viewmodel.dart, home_screen.dart, fan_post.dart, fan_comment.dart, fan_post_service.dart, fan_page_screen.dart, my_posts_screen.dart, create_fan_post_screen.dart, fan_post_detail_screen.dart, main_shell.dart, profile_screen.dart |
| 2026-05-11 | Added shared assistant workflow file for Codex + Claude with mandatory reason logging, verification logging, MVVM discipline, and guidance to avoid unnecessary black backgrounds from Figma carryover | TEAM_WORKFLOW.md, AGENTS.md, CLAUDE.md |
| 2026-05-11 | Figma photos + manifesto data complete — replaced all Icon placeholders with real Figma images: vijay_home_hero.png in hero area, vijay_hero.png in Join TVK card, leader_vijay/anand/arunraj/aadhav.png in Know Your Leaders grid. ManifestoPlan model got imageAsset+bullets fields; manifesto_screen.dart uses plan.imageAsset directly; manifesto_detail_screen.dart Key Goals reads plan.bullets (falls back to defaults if empty). leader_screen.dart campaign images fixed to campaign1.png + campaign2.png. Zero analyzer issues. | home_screen.dart, manifesto_screen.dart, manifesto_detail_screen.dart, leader_screen.dart, models/manifesto_plan.dart, services/content_service.dart |
| 2026-05-11 | Home screen complete — added Campaign Toolkit section (horizontal scroll of 4 poster cards with Share button), TVK Television card (dark red gradient → YoutubeHubScreen), redesigned Community Wall card (white bg, 3 post previews with avatar initials), Figma-exact Poll card (red #9F1D1F checkbox, 48px options, green Get TVK Badge pill). Manifesto banner now shows vijay_hero.png. Zero analyzer issues. | home_screen.dart |
| 2026-05-11 | Figma-exact screen rebuilds — PollsScreen (Take Action: filter chips Polls/Complaints/Donation, red 48px option rows, TVK Badge pill), NewsScreen (Latest News: section groups Speeches/Highlights/Tweets, white cards with 166px thumbnail + play button + category pill + likes/share footer), ProfileScreen (Existing Profile: avatar + stats row + Area Pulse + Local Members + About TVK), SettingsScreen (new: Edit Profile, Notification/Theme toggles, Language buttons, Log out / Delete account). All screens use #F6F6F6 bg, white top app bar, Plus Jakarta Sans font, primary #9F1D1F. Zero analyzer issues. | polls_screen.dart, news_screen.dart, profile_screen.dart, settings_screen.dart (new) |
| 2026-05-11 | Fixed home_screen.dart compile error (orphaned brackets from prior edit). Added_SocialJusticeSection — swipeable PageView of 5 TVK ideology leaders (Periyar, Kamarajar, Ambedkar, Velunachiyar, Anjalai Ammal) with left/right arrow nav, dot indicators, dark red gradient cards. Zero analyzer issues. | home_screen.dart |
| 2026-05-11 | Created ROADMAP.md — full architecture (local→staging→prod on AWS ECS Fargate), PostgreSQL+pgvector DB schema, RAG implementation plan, 7-phase build plan, Docker Compose full stack target, cost estimate. Mandatory reading for all AI agents. | ROADMAP.md, CLAUDE.md, AGENTS.md, TEAM_WORKFLOW.md |
| 2026-05-11 | Started backend chat persistence foundation on `codex/backend-chat-persistence` — added DB-backed session/message storage in agent service and new `GET /sessions` endpoint; chat persistence no longer depends on the in-memory dict | services/agent/db.py, services/agent/agent.py, services/agent/main.py |
| 2026-05-12 | Admin UI complete redesign — dark sidebar nav (Knowledge Base / Add Content sections), stats cards, source-type badges (Manual/File/URL/YouTube), color-coded similarity progress bars on Test Retrieval, audit log with category filter pills, design token system | services/admin-ui/src/App.jsx |
| 2026-05-12 | Firebase token verification — new auth.py module: dev mode decodes JWT payload without verification (local dev unaffected), production mode uses firebase-admin SDK for full cryptographic verification. /chat and /sessions now return 401 on invalid token in prod. FIREBASE_SERVICE_ACCOUNT_JSON /_PATH env vars added. firebase-admin==6.5.0 added to requirements. | services/agent/auth.py (new), services/agent/main.py, services/agent/requirements.txt, docker-compose.yml, .env |
| 2026-05-12 | Fixed critical empty-reply bug — role anchor was appended AFTER the last user message; model receiving system message as final turn generated 0 tokens. Fixed: role anchor now inserted before the last user message. RAG similarity threshold raised 0.4→0.55 to stop noise queries (greetings etc.) from triggering irrelevant context injection. | services/agent/agent.py, services/agent/rag.py |
| 2026-05-12 | Admin UI: replaced ADD CONTENT sidebar items with a single ＋ Add Content FAB (bottom-right). Tap opens a centred modal with 4 segment tabs (Paste Text / Upload File / Scrape URL / YouTube). Sidebar now shows only KNOWLEDGE BASE nav items. Modal closes on Escape or backdrop click, auto-closes after successful add. | services/admin-ui/src/App.jsx |
| 2026-05-12 | Flutter chat hardening — sendMessage timeout raised 60→90s; empty reply now throws instead of creating empty bubble; network errors surface readable messages (timeout vs unreachable); getSessions no longer throws on failure (returns empty list so UI stays functional). | mobile/app/lib/services/agent_service.dart |
| 2026-05-12 | Fixed language detection — AI was replying in Tamil even when user typed in English. Root cause: model anchored to Tamil from conversation history. Fix: role_anchor() now detects Unicode script of each user message (Tamil block ஀-௿ / Devanagari / Latin) and injects an explicit per-turn LANGUAGE instruction ("Reply ONLY in English. Do NOT use Tamil."). Works correctly across language switches mid-conversation. | services/agent/guard.py, services/agent/agent.py |
| 2026-05-12 | Fixed YouTube transcript (youtube-transcript-api 0.6.2→1.2.4 — completely new API; old class-method API removed). Rewrote get_youtube_transcript() for v1.x: api.list()/api.fetch(), FetchedTranscriptSnippet.text instead of dict["text"], language priority ta→en→any. Fixed URL scraper: 3-pass extraction (main area → all p/li/h tags → full body), improved User-Agent, better error message for JS-rendered sites. | services/agent/scraper.py, services/agent/requirements.txt |
| 2026-05-12 | Default system prompts now live in DB and are admin-editable — not in .env. New `personas` table seeded once from persona.SEED_PERSONAS on init_db(); admin UI gained "System Prompt" page with monospace editor, char/word counts, unsaved-changes indicator, and Reset-to-default. Backend endpoints: GET/PUT/POST /admin/personas[/{flavor_id}][/reset]. agent.py refreshes the session's system message from DB on every call so edits take effect on the next turn (existing chats included). Audit log records persona_updated / persona_reset. | services/agent/db.py, services/agent/persona.py, services/agent/agent.py, services/agent/main.py, services/admin-ui/src/App.jsx |
| 2026-05-13 | Realtime 3D avatar + streaming voice — additive scaffold, existing /chat untouched. New WebSocket `/ws/chat` streams Ollama tokens with sentence-level early flush (first comma), spawns parallel edge-tts MP3 synthesis per sentence, and sends interleaved text + binary audio frames. Avatar pipeline: photo or RPM GLB URL → cached GLB served by `GET /avatar/{id}.glb`. New `avatars` table + register/list/get/delete helpers. Web client (`services/web-avatar/`) renders the GLB with @react-three/fiber, drives ARKit `jawOpen` blendshape from a shared Web Audio AnalyserNode, plays MP3 sentences in order through one `<audio>` element. Pluggable photo→3D provider hook via `PHOTO_TO_AVATAR_API` env. Sub-1s first-audio latency on the early-flush path. | services/agent/streaming.py (new), services/agent/tts.py (new), services/agent/avatar_gen.py (new), services/agent/main.py, services/agent/db.py, services/agent/requirements.txt, services/web-avatar/* (new), .gitignore |
| 2026-05-13 | Admin UI Avatars page — new sidebar section between Audit Log and Prompts with 🧑 Avatars entry. Page has segmented "From GLB URL" / "Upload Photo" form (name + url or name + file), avatar grid showing source badge (URL / Photo / Photo-placeholder), creation time, GLB download link, and delete action. Per-flavor filtered via existing flavor switcher. AddFab hidden on this page (matches Prompts behavior). | services/admin-ui/src/App.jsx |
| 2026-05-13 | Offline-friendly procedural 3D avatar — ProceduralAvatar.jsx renders a stylized head from Three.js primitives (no GLB, no network). AvatarCanvas falls back to it when `glbUrl` is null, a HEAD probe returns 404, or GLB loading throws. Built-in dropdown option always present in the web client. Photo upload no longer fails when readyplayer.me is DNS-blocked — record is saved with needs_regeneration=true and the canvas renders procedural for it. Default-GLB env hints added (DEFAULT_AVATAR_URL, LOCAL_DEFAULT_GLB, PHOTO_TO_AVATAR_API). | services/web-avatar/src/ProceduralAvatar.jsx (new), services/web-avatar/src/AvatarCanvas.jsx, services/web-avatar/src/App.jsx, services/agent/avatar_gen.py, .env |
| 2026-05-13 | Sketchfab embed avatars — new first-class avatar type for networks that DNS-block readyplayer.me but allow sketchfab.com. avatars table gains embed_url column (migration safe). New `POST /admin/avatars/from-embed` endpoint. Admin UI gets "🎬 From Sketchfab" tab (now the default) with embed URL field. SketchfabViewer.jsx loads the Sketchfab Viewer API and drives morph targets for lip sync where available, falling back to silent playback when the model has none. Auto-seeded on startup from DEFAULT_SKETCHFAB_EMBED env (pre-filled with the "Vijay the Master 3D" model). DEFAULT_SKETCHFAB_NAME and DEFAULT_SKETCHFAB_FLAVOR for naming/flavor binding. | services/agent/db.py, services/agent/main.py, services/admin-ui/src/App.jsx, services/web-avatar/src/SketchfabViewer.jsx (new), services/web-avatar/src/App.jsx, services/web-avatar/src/styles.css, .env |
| 2026-05-13 | D-ID Streams photoreal talking-photo integration — uploads a face photo to api.d-id.com, opens a WebRTC peer connection (browser ↔ D-ID, our backend proxies signaling so the API key stays server-side), pushes each sentence from the LLM stream to `/talks/streams/{id}` and the browser renders the resulting lip-synced video. Avatars table gains did_source_url + did_voice_id columns. New endpoints: /admin/avatars/from-did-photo, /did/stream/{create,sdp,ice,talk,close}. New web component DIDViewer.jsx with imperative .speak() handle. useAvatarChat exposes onSentence + muteLocalAudio (D-ID streams its own audio). Admin UI gets a "👤 Talking Photo (D-ID)" tab (now default) with voice id field. DID_API_KEY env var. | services/agent/did.py (new), services/agent/main.py, services/agent/db.py, services/web-avatar/src/DIDViewer.jsx (new), services/web-avatar/src/App.jsx, services/web-avatar/src/useAvatarChat.js, services/web-avatar/src/styles.css, services/admin-ui/src/App.jsx, .env |
| 2026-05-13 | MVP1 self-hosted avatar pipeline + gateway architecture — pivoted from cloud APIs (D-ID/Sketchfab/RPM) to a self-hosted stack because the dev box has no NVIDIA GPU. New services/avatar-service/ (port 8002) and gateway services/run.py (port 9000) that boots agent (8001) + avatar-service (8002) as subprocesses and reverse-proxies HTTP + WebSocket based on path prefix. Frontends point at :9000 only. avatars table gains face_avatar_id + piper_voice_id columns. New endpoint POST /admin/avatars/face. WS /ws/chat accepts avatar_id and routes TTS to avatar-service when face avatar selected. Admin UI gets "📸 Face Photo" tab as the default. Hotfix: replaced piper-tts with edge-tts (piper-phonemize has no Python 3.13 wheels), and switched .env loading to absolute Path(**file**).resolve().parents[2] so DATABASE_URL no longer falls back to the wrong default under uvicorn's reloader subprocess. | services/run.py (rewritten), services/avatar-service/* (new), services/agent/avatar_client.py (new), services/agent/main.py, services/agent/agent.py, services/agent/db.py, services/web-avatar/src/App.jsx, services/web-avatar/src/useAvatarChat.js, services/web-avatar/src/styles.css, services/admin-ui/src/App.jsx |
| 2026-05-13 | MVP2 + MVP3-lite — Canvas-based 2D talking-head animation. New FacePhotoCanvas.jsx replaces the static-<img> FacePhotoStage. Single requestAnimationFrame loop drives: (a) mouth opening as a dark ellipse scaled by audio amplitude from SentenceAudioPlayer.AnalyserNode, (b) random eye blinks (~every 3-6s) drawn as skin-toned bars sampled from the photo, (c) subtle head sway via canvas rotate. Mouth/eye positions are fractional bbox heuristics — accurate for centered forward-facing portraits, will be replaced with face-api.js landmarks in MVP2.5 if needed. OpenVoice clone (the other MVP3 item) is explicitly deferred — 2-3s CPU latency made it not worth shipping for realtime, kept as an offline batch tool for future. | services/web-avatar/src/FacePhotoCanvas.jsx (new), services/web-avatar/src/App.jsx, services/web-avatar/src/styles.css |
| 2026-05-14 | Cleanup PR — deleted all non-face avatar paths. Removed files: services/agent/{avatar_gen.py, did.py}; services/web-avatar/src/{AvatarCanvas.jsx, ProceduralAvatar.jsx, SketchfabViewer.jsx, DIDViewer.jsx}; services/avatar-service/piper_tts.py shim. Stripped from main.py: AvatarFromUrlRequest, AvatarFromEmbedRequest, DID*Request models; endpoints /admin/avatars/{from-url,from-embed,from-photo,from-did-photo}, /did/stream/{create,sdp,ice,talk,close}, GET /avatar/{id}.glb; *seed_default_sketchfab_avatar() startup hook. db.py: dropped columns photo_filename, source_url, embed_url, did_source_url, did_voice_id, needs_regeneration via DROP COLUMN IF EXISTS; simplified register_avatar signature to (id, name, flavor_id, face_avatar_id, piper_voice_id); removed get_avatar_by_embed_url. web-avatar/package.json: removed three, @react-three/fiber, @react-three/drei deps. web-avatar/App.jsx: dropped the 4-way cascade, only renders FacePhotoCanvas or empty-state. admin-ui/App.jsx: AvatarsView collapsed to a single form (no more 5-tab segment), AvatarCard simplified to one badge. .env: removed DEFAULT_AVATAR_URL, LOCAL_DEFAULT_GLB, PHOTO_TO_AVATAR_API, DEFAULT_SKETCHFAB**, DID_API_KEY, DID_API_BASE; added GATEWAY_PORT + AVATAR_SERVICE_URL hints. ~700 lines deleted net. | services/agent/main.py, services/agent/db.py, services/admin-ui/src/App.jsx, services/web-avatar/src/App.jsx, services/web-avatar/package.json, .env (+ deletions listed above) |
| 2026-05-14 | MVP2.5 — MediaPipe Face Landmarker for accurate mouth positioning. New faceLandmarks.js wraps @mediapipe/tasks-vision (478-point face mesh, WASM + model loaded from jsDelivr/Google CDN on first photo). On photo upload, browser detects mouth + eye bboxes once and FacePhotoCanvas uses them instead of fraction heuristics. Falls back to centered defaults with a clear "Face not detected" warning if MediaPipe fails to load or no face is found. Censor-bar blink overlay removed — looked bad without proper eyelid warping; idle blink can come back in MVP3 with curved mask + skin sampling from the brow. Mouth ellipse made narrower (0.30 of bbox width) so the dark doesn't leak past the lips at high amplitude. | services/web-avatar/package.json, services/web-avatar/src/faceLandmarks.js (new), services/web-avatar/src/FacePhotoCanvas.jsx, services/web-avatar/src/styles.css |
| 2026-05-14 | gpu-avatar service scaffolded for LivePortrait + audio2motion (mock pipeline now, real pipeline later). New service on port 8003 with HTTP contract: POST /gpu-svc/sources (photo→source_id), POST /gpu-svc/sources/{id}/speak (audio→task_id), GET /gpu-svc/streams/{task_id} (MJPEG multipart/x-mixed-replace at 25fps), GET /gpu-svc/sources/{id}/idle (continuous idle stream). Mock pipeline renders source photo with amplitude-driven cartoon mouth using PIL/numpy — same wire format the real GPU pipeline will use. Swap is one file replacement (`mock_pipeline.py` → `real_pipeline.py` with LivePortrait + an audio2motion model like Real3D-Portrait / GeneFace++). Gateway proxy upgraded from `await client.request` to `client.send(stream=True)` + StreamingResponse so MJPEG / SSE / large file responses don't block. SERVICES table in run.py now boots all three. GPU_AVATAR_URL env hint added. | services/gpu-avatar/* (new), services/run.py, .env, CLAUDE.md |
| 2026-05-14 | Per-service enable/disable flags in run.py. SERVICES table gains enabled_env / default_enabled / required_envs keys. _is_enabled() reads ENABLE_AGENT / ENABLE_AVATAR_SERVICE / ENABLE_GPU_AVATAR / ENABLE_TAVUS from .env (truthy = 1/true/yes/on; falsy = 0/false/no/off). Services with `required_envs` (e.g. tavus-service needs TAVUS_API_KEY) are auto-skipped if those vars are unset, with a clear log line. Gateway proxy returns `503 {service disabled, reason}` JSON for any HTTP request to a disabled prefix, and `4503` WebSocket close for disabled WS paths — no more `ConnectionRefused` confusion. /_gateway/services now reports `enabled` + `reason` per service. tavus-service entry pre-wired in SERVICES (cwd doesn't exist yet, so it skips gracefully until that service is scaffolded next session). | services/run.py, .env |
| 2026-05-14 | tavus-service scaffolded (Phase 1 — Tavus built-in LLM, no webhook). New service on port 8005 with HTTP proxy in front of api.tavusapi.com. Endpoints: GET /tavus-svc/replicas, GET /tavus-svc/personas, POST /tavus-svc/conversations (returns Daily.co room URL), GET/DELETE /tavus-svc/conversations/{id}. Auth via TAVUS_API_KEY (server-side only — never sent to browser). TAVUS_SYSTEM_PROMPT default sets the Vijay/TVK persona inline as `conversational_context`. Custom-LLM webhook stubbed at /tavus-svc/webhook for Phase 2 (Ollama+RAG via ngrok / Cloudflare Tunnel). Smoke test: POST /tavus-svc/conversations with a stock replica_id → open the returned conversation_url in a browser tab for live two-way video chat with no further client code. | services/tavus-service/* (new), CLAUDE.md |
| 2026-05-14 | tavus-service personal replica training (face + voice cloning). Tavus trains face and voice from one video — no separate voice-only path in CVI. New endpoints: POST /tavus-svc/replicas (kick off training from a public https video URL — Tavus pulls and processes ~30-60 min), GET /tavus-svc/replicas/{id} (poll status: pending → training → ready), DELETE /tavus-svc/replicas/{id}. tavus_client gained create_replica / get_replica / delete_replica. Once ready, the same /tavus-svc/conversations endpoint uses the trained replica_id and the CVI speaks with Vijay's actual cloned voice + face. README documents the dashboard path (https://platform.tavus.io) as the no-code alternative, plus consent/ToS caveat for public-figure cloning. | services/tavus-service/main.py, services/tavus-service/tavus_client.py, services/tavus-service/README.md |
| 2026-05-14 | Mobile voice mode + STT gateway wiring + Fish TTS verifier. services/agent/test_fish.py is a standalone smoke test for the cloned voice (saves test_fish_output.mp3; .env loaded from absolute project root). services/run.py SERVICES table picked up a stt entry (cwd=services/sst, prefix=/stt/, ENABLE_STT=true by default) so the gateway proxies /stt/transcribe to faster-whisper on 8004. New REST endpoint POST /tts on the agent returns MP3 bytes via the same synthesize_sentence path the WS uses (Fish when TTS_ENGINE=fish). Mobile pubspec gained record, just_audio, permission_handler, path_provider deps. AgentService gained transcribe(File) → text and synthesizeSpeech(text) → MP3 bytes. chat_screen.dart rewritten: floating mic button + av1.png halo above it (per design), voice mode auto-engages on first mic tap, autoplays cloned-voice replies for subsequent mic turns, typing the text field is always text-only (no TTS regardless of voice mode), header shows a "voice on" indicator with manual silence toggle. | services/agent/test_fish.py (new), services/run.py, services/agent/main.py, .env, mobile/app/pubspec.yaml, mobile/app/lib/services/agent_service.dart, mobile/app/lib/screens/chat_screen.dart |
| 2026-05-14 | STT 404 fix + chat-screen redesign + record_linux build fix. STT app/__init__.py now mounts transcribe router twice — bare /transcribe + /asr (for direct port 8004 calls) AND prefixed /stt/transcribe + /stt/asr (for gateway-routed calls via :9000). chat_screen.dart redesigned: tvk_flag.png as the AppBar avatar (replaces person icon), Media.jpg (copied into assets/images/) in the empty state (replaces auto_awesome sparkle), mic button moved inline next to the send button at the bottom (removes the floating mic+avatar overlay). Input row is now: [textbox] [mic] [send]. Voice mode state machine unchanged — first mic tap engages voice mode, subsequent replies autoplay until user taps the "graphic_eq" header icon to silence. pubspec dependency_overrides pinned record_platform_interface:1.2.0 + record_linux:0.7.2 to fix the Linux subplatform compile error during Android builds. | services/sst/app/__init__.py, mobile/app/lib/screens/chat_screen.dart, mobile/app/pubspec.yaml, mobile/app/assets/images/Media.jpg (new) |
| 2026-05-14 | Mobile gateway port fix + Hotstar-style replay button. Root cause of the persistent /stt/transcribe 404: app_config.dart defaulted to port 8001 (agent direct) which has no STT routes. Flipped default API URL to :9000 (gateway). New _ReplayButton widget in the AppBar — always visible. Tap = replay the last AI reply with the cloned voice AND auto-engage voice mode; long-press = silence. Filled-red when voice mode on, gray outline when off, pulsing while playing. New _onReplayTap() finds the last assistant message, stops any playing audio, and re-synthesises via /tts. _replayingLast flag drives the pulse animation. | mobile/app/lib/config/app_config.dart, mobile/app/lib/screens/chat_screen.dart |
| 2026-05-14 | STT Tamil auto-detect + new-reply playback fix. Root cause of "speech recognition not working": STT route hardcoded `lang = "en"` when the input language wasn't in SUPPORTED_LANGUAGES, so Tamil audio was sent to faster-whisper with language="en" and produced garbage. Fix: route now defaults to `lang = None` (faster-whisper auto-detects across all 99 languages), accepts ?language=ta to force Tamil, ?language=auto explicitly. Engine signature `transcribe_file(lang: str | None)` updated; `_model_id_for(None)` returns the multilingual model. SUPPORTED_LANGUAGES extended with ta + hi. Mobile _speak() now calls `_player.stop()` before each new playback so a fresh reply mid-conversation actually plays (previously the still-playing player ignored the next setFilePath). Mobile transcribe() error toast now includes the failing URL so future 404s are debuggable. | services/sst/app/core/config.py, services/sst/app/api/routes/transcribe.py, services/sst/app/services/stt_engine.py, mobile/app/lib/services/agent_service.dart, mobile/app/lib/screens/chat_screen.dart |
| 2026-05-14 | STT octet-stream fix + TTS disk cache + stale-playback discard. STT was rejecting Flutter's default `application/octet-stream` MIME on /stt/transcribe (mobile MultipartFile.fromPath doesn't sniff .m4a). Fix: route accepts octet-stream + empty Content-Type and falls back to filename-extension sniff against `.m4a/.wav/.mp3/.ogg/.webm/.flac/.aac`. Mobile additionally sets explicit `MediaType('audio','mp4')` (or matching mime per extension) using http_parser so future builds send proper Content-Type. Agent /tts now disk-caches MP3 by sha256(text|voice|engine|fish_voice_id) under services/agent/data/tts_cache/ — repeat phrases return in <10 ms instead of paying Fish's 1-3 s cloud roundtrip; X-Cache: HIT/MISS header reports which path served. Mobile _speak() got a monotonic generation counter — if a newer mic turn supersedes the previous reply while Fish is still synthesising, the old TTS bytes are discarded before playback (fixes "old voice telling, not latest one"). | services/sst/app/api/routes/transcribe.py, services/agent/main.py, mobile/app/lib/services/agent_service.dart, mobile/app/lib/screens/chat_screen.dart, mobile/app/pubspec.yaml |
| 2026-05-14 | TTS background prefetch + observability. /chat is now async and schedules a FastAPI BackgroundTask to call _tts_warm() on the reply immediately after returning the response. Fish's 1-3 s synth typically completes during the 50-200 ms gap before mobile calls /tts, so the next request sees X-Cache: HIT instead of MISS — perceived latency drops from "wait for Fish" to "instant playback". Every /tts request now logs a single visible line: [TTS] HIT  9234 B  abc123.mp3  text='...' or [TTS] MISS .... New /tts/cache/stats reports { cache_dir, entries, total_kb, newest } for ops visibility. New DELETE /tts/cache wipes the cache (use after switching Fish voice ids). | services/agent/main.py |
| 2026-05-14 | Tamil-flavor language lock. Whisper auto-detect was mis-transcribing short Tamil utterances as Hindi (Devanagari) → role_anchor saw Hindi script → LLM was told "reply in Hindi" → entire conversation flipped to Hindi mid-session. Two-layer fix: (1) mobile chat_screen.dart force-passes `language: 'ta'` to /stt/transcribe when AppConfig.flavorName == 'tn-tvk' (no auto-detect for Tamil sessions), (2) guard.py _detect_script() is now flavor-aware — for tn-tvk, Devanagari input is silently treated as Tamil so the language:tamil prompt fires instead of language:hindi. Documented the 3 prompt keys (persona:tn-tvk, role_anchor:tn-tvk, language:*) and recommended persona LANGUAGE-RULE edit via admin UI to remove the Hindi fallback for the Tamil platform. | mobile/app/lib/screens/chat_screen.dart, services/agent/guard.py |
| 2026-05-14 | Per-message speaker icon + sentence-level TTS pacing. Every AI message bubble now has a tappable speaker icon to its left — tap replays only that message in Vijay's voice and engages voice mode for future replies. Replies are split client-side into sentences (`[^.!?।]+` regex covers English period, Tamil/Hindi danda, ellipsis); each sentence hits /tts independently and plays sequentially with a 400 ms natural gap between. Each sentence is independently cacheable on the agent's disk cache — repeat phrases inside a long reply also become instant. _speakGen counter still cancels mid-stream playback if the user starts a new mic turn before all sentences finished. WebSocket streaming migration (real time-to-first-audio fix) deferred to a separate PR. | mobile/app/lib/screens/chat_screen.dart |
| 2026-05-14 | Free mic during TTS playback + interrupt-on-tap + status pill. Bug user reported as "speech recognition taking time even after chat response came" was actually `_processing` staying true through the entire 5-15 s sentence-by-sentence TTS playback, blocking the mic button until all audio finished. Fix: split state into `_processing` (STT + LLM only, blocks mic) and `_speaking` (TTS audio, mic stays usable, tap interrupts). Tapping mic while Vijay is speaking calls `_interruptPlayback()` which stops the player and bumps `_speakGen` to cancel in-flight Fish calls. Added `_stage` state (idle | listening | transcribing | thinking | speaking) shown as a small pill in the AppBar with matching icon — user can see what's actually running instead of guessing from a generic spinner. | mobile/app/lib/screens/chat_screen.dart |
| 2026-05-14 | Cache-only per-message replay + sentence-aligned prefetch. Per-message speaker (now BELOW each AI bubble, right-aligned) calls /tts?strict_cache=true — returns 404 instead of falling through to Fish. _speakCachedOnly does a pre-flight fetch of every sentence; if any one isn't cached the whole replay is silent (no half-replays). Voice-mode auto-play after mic still uses the regular /tts so the very first reply works. Server-side: /chat background prefetch now splits the reply into sentences first (via _tts_warm_sentences) so per-sentence /tts calls from mobile actually HIT the cache — previously the whole-reply hash never matched the per-sentence hashes mobile asked for. | services/agent/main.py, mobile/app/lib/services/agent_service.dart, mobile/app/lib/screens/chat_screen.dart |
| 2026-05-14 | TVK Family screen — replaced 10 mock district groups with all 234 real TVK election candidates from tvkvijay.com across 38 districts (Tiruvallur→Kanyakumari, constituency nos. 1–234). Vijay/Anand/Arunraj/Aadhav mapped to their real constituencies with photo assets. | policy_leaders_screen.dart |
| 2026-05-14 | Vijay detail page (separate from other leaders) — VijayDetailScreen with white hero (portrait, name, role, location pill), About tab (info table + personal background + career summary), Achievements tab (Cinema section with image, Public Service, Historic Events). Wired from home screen Vijay mini-card. | vijay_detail_screen.dart (new), home_screen.dart |
| 2026-05-14 | Shorts row now dynamic — _TvkShortsRow accepts List<YouTubeVideo> from HomeViewModel.recentShorts; shows real YouTube thumbnail+title when loaded, falls back to placeholder assets. | home_screen.dart |
| 2026-05-14 | Manifesto renamed to Projects — header title updated to "TVK's PROJECTS", subtitle updated, home screen cinematic card label changed from "Manifesto" to "Projects". | manifesto_screen.dart, home_screen.dart |
| 2026-05-14 | News screen advanced filters — added Filter toggle button next to search, animated expand/collapse panel with District (12 TN districts), Sector (10 verticals: Education/Child Care/PWD/Health etc.), Ministry (9 ministries) horizontal-scroll chip rows. Active filter dot indicator on toggle button. Clear all button when any filter active. | news_screen.dart |
| 2026-05-14 | Campaign Toolkit detail pages — CampaignToolkitDetailScreen with gradient header, 2-col grid of items per toolkit type (Posters/Media/Slogans/Hashtags). Each card shows real campaign image with Share chip overlay. Toolkit cards now use campaign1/campaign2/campaign_2.png images. GestureDetector wraps each card → navigates to detail. | campaign_toolkit_detail_screen.dart (new), home_screen.dart |
| 2026-05-14 | Join TVK full flow — JoinScreen (real TextControllers, district/gender pickers, DOB date picker, validation) → FaceCaptureScreen (image_picker camera/gallery, face guide corner frame, flash toggle, retake/use-photo actions) → MemberIdScreen (white bg, red glow, TVK ID card with captured photo slot, yellow-red ACTIVE MEMBER badge, Back to Home popUntilFirst). image_picker 1.1.2 added. iOS camera + photo library permissions added. Events back button added. TVK TV simplified to single tv_flat_screen.png. Hero Join Now fixed to navigate to JoinScreen. Zero analyzer issues. | join_screen.dart, face_capture_screen.dart (new), member_id_screen.dart, pubspec.yaml, ios/Runner/Info.plist, home_screen.dart, events_screen.dart |
| 2026-05-14 | Login/Join gate — Profile tab + Chat FAB require login; _requireLoginThen() pattern shows bottom sheet with Login/Skip; post-login _promptJoinTvk() shows ACTIVE MEMBER badge + Join TVK Now sheet. News filters converted from inline panel to DraggableScrollableSheet (district/sector/ministry, clear all, apply). Campaign song overflow fixed (Positioned bounds). Events home cards redesigned (red date block left, title+badge right). REQUIREMENTS.md fully updated. | main_shell.dart, news_screen.dart, home_screen.dart, REQUIREMENTS.md |
| 2026-05-14 | App name → "My TVK" (iOS + Android). App icon generated from vijay_home_hero.png via flutter_launcher_icons. Projects screen fully rebuilt to Figma: segmented tabs, 5-Year Plans (orange timeline + cards), Visions (Vijay portrait + side menu + policy card), Goals & Achievements (circular progress + achievement cards). Detail page rebuilt: grey title header, description, BebasNeue milestone timeline with red center line. ManifestoPlan model extended with ministry + milestones fields. 15 unused assets removed. | Info.plist, AndroidManifest.xml, pubspec.yaml, manifesto_plan.dart, content_service.dart, manifesto_screen.dart, manifesto_detail_screen.dart |
