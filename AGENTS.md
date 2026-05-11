# Political Platform — Project Knowledge Base

> This file is the single source of truth for this project.
> It is read by Codex at the start of every session.
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
└── AGENTS.md               # ← this file
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
| 2026-05-11 | Fixed Firebase OTP config drift — stopped forcing simulator test phone auth by default and corrected iOS Firebase bundle ID case to match Xcode/GoogleService config | mobile/app/lib/screens/phone_login_screen.dart, mobile/app/lib/firebase_options.dart |
| 2026-05-11 | Updated Home hero section to better match Figma dashboard node 948:1148 while keeping the app light: rebuilt top header band, Tamil title/tagline block, right-side leader image composition, Join TVK card, and Community Wall card placement/style | mobile/app/lib/screens/home_screen.dart |
| 2026-05-11 | Fixed home_screen.dart compile error (orphaned brackets). Added _SocialJusticeSection with 5 ideology leaders, swipeable PageView, arrow nav, dot indicators. | home_screen.dart |
| 2026-05-11 | Created ROADMAP.md — full architecture local→staging→prod, DB schema, RAG plan, 7 phases, Docker Compose full stack, cost estimate, AI agent instructions | ROADMAP.md, CLAUDE.md, AGENTS.md, TEAM_WORKFLOW.md |
