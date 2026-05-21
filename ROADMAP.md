# Political Platform — Full Architecture & Roadmap

> **This file is mandatory reading for every AI agent (Claude, Codex, or any other) before touching this repo.**
> Read `CLAUDE.md` → `AGENTS.md` → `TEAM_WORKFLOW.md` → this file, in that order.
> Update the **Completed Phases** section at the bottom every time a phase or milestone is finished.

---

## What We Are Building

A multi-client political AI agent platform. Citizens talk to their political leader via an AI agent. Built to scale to 5 crore (50 million) users. Supports Tamil and English.

**Current live client:** TVK (Tamilaga Vettri Kazhagam) — flavor ID `tn-tvk`
**Second client planned:** `india-pm`

---

## High-Level Architecture (Now → Production)

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APP                               │
│              Flutter (iOS + Android)                            │
│         Firebase Auth (Phone OTP) → JWT                         │
└───────────────────────┬─────────────────────────────────────────┘
                        │ HTTPS / REST
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY (future)                         │
│              AWS API Gateway or Nginx                           │
│         Rate limiting · Auth · SSL termination                  │
└───────────────────────┬─────────────────────────────────────────┘
                        │
          ┌─────────────┼──────────────┐
          ▼             ▼              ▼
  ┌───────────┐  ┌───────────┐  ┌───────────┐
  │  Agent    │  │  Content  │  │  User     │
  │  Service  │  │  Service  │  │  Service  │
  │  :8001    │  │  :8002    │  │  :8003    │
  │ (FastAPI) │  │ (FastAPI) │  │ (FastAPI) │
  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
        │               │               │
        ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     POSTGRESQL (RDS)                            │
│   chat_sessions · chat_messages · users · documents (pgvector)  │
│               polls · news · events · complaints                │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────┐     ┌──────────────────┐
│  REDIS (cache)  │     │  OLLAMA / LLM    │
│  Sessions       │     │  gpt-oss:20b-cloud local  │
│  Rate limits    │     │  OR AWS Bedrock  │
│  OTP cache      │     │  on prod         │
└─────────────────┘     └──────────────────┘
```

---

## Where Things Run

### Now (Local Development)

| Service | Where | URL |
|---|---|---|
| Flutter app | Your Mac, Xcode simulator or physical device | — |
| FastAPI agent | Your Mac, conda env `political-agent` | `http://<LAN-IP>:8001` |
| Ollama LLM | Your Mac | `http://localhost:11434` |
| Database | None yet — in-memory + SharedPreferences | — |

### Next (Staging — single server)

| Service | Where | URL |
|---|---|---|
| Flutter app | TestFlight (iOS) / APK sideload (Android) | — |
| FastAPI agent | 1× AWS EC2 t3.medium (ap-south-1 Mumbai) | `https://api.tvk.app` |
| PostgreSQL + pgvector | AWS RDS PostgreSQL 16 (same region) | Internal VPC |
| Redis | AWS ElastiCache t3.micro | Internal VPC |
| Ollama / LLM | Same EC2 or AWS Bedrock Claude Haiku | Internal |

### Production (Scale — ECS Fargate)

| Service | Where | Config |
|---|---|---|
| Flutter app | App Store + Google Play | — |
| FastAPI services | AWS ECS Fargate (ap-south-1) | Auto-scaling, 2–10 tasks |
| PostgreSQL | AWS RDS Multi-AZ (ap-south-1) | db.t3.large, backups on |
| Redis | AWS ElastiCache cluster | cache.t3.medium |
| LLM | AWS Bedrock (Claude Haiku/Sonnet) | Per-call billing, no GPU needed |
| CDN | AWS CloudFront | Static assets, app images |
| DNS | Route 53 | `api.tvk.app` → ALB |

---

## Monorepo Structure (Current + Planned)

```
political-platform/
├── mobile/
│   └── app/                        # Flutter iOS + Android
│       ├── lib/
│       │   ├── config/             # Flavor, API URL, secrets
│       │   ├── models/             # Pure data classes
│       │   ├── viewmodels/         # MVVM state + logic
│       │   ├── services/           # API, storage, Firebase
│       │   └── screens/            # UI only
│       └── ios/ android/
│
├── services/
│   ├── agent/                      # ✅ BUILT — Chat AI (FastAPI :8001)
│   │   ├── main.py
│   │   ├── agent.py
│   │   ├── persona.py
│   │   ├── rag.py                  # 🔲 TO BUILD — RAG search
│   │   ├── ingest.py               # 🔲 TO BUILD — Document ingestion
│   │   └── Dockerfile
│   │
│   ├── content/                    # 🔲 TO BUILD — News/Events/Polls (FastAPI :8002)
│   │   ├── main.py
│   │   └── Dockerfile
│   │
│   └── user/                       # 🔲 TO BUILD — Auth/Profile/KYC (FastAPI :8003)
│       ├── main.py
│       └── Dockerfile
│
├── infra/                          # 🔲 TO BUILD — Infrastructure as code
│   ├── terraform/                  # AWS resources
│   └── docker-compose.prod.yml
│
├── data/                           # 🔲 TO BUILD — RAG documents
│   ├── manifesto/                  # TVK manifesto PDFs / text
│   ├── speeches/                   # Vijay's speeches
│   ├── policies/                   # Government scheme documents
│   └── faq/                        # Party FAQ
│
├── docker-compose.yml              # ✅ BUILT (agent only, expand to full stack)
├── CLAUDE.md                       # ✅ Instructions for Claude
├── AGENTS.md                       # ✅ Instructions for Codex
├── TEAM_WORKFLOW.md                # ✅ Shared workflow rules
└── ROADMAP.md                      # ✅ This file
```

---

## Database Schema (PostgreSQL)

### Phase 1 — Core tables (build first)

```sql
-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_e164 TEXT UNIQUE NOT NULL,       -- +919876543210
    firebase_uid TEXT UNIQUE NOT NULL,
    name TEXT,
    constituency TEXT,
    state TEXT DEFAULT 'Tamil Nadu',
    flavor_id TEXT DEFAULT 'tn-tvk',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Chat sessions
CREATE TABLE chat_sessions (
    id TEXT PRIMARY KEY,                   -- session_id from app
    user_id UUID REFERENCES users(id),
    flavor_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    last_active_at TIMESTAMPTZ DEFAULT now()
);

-- Chat messages
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT REFERENCES chat_sessions(id),
    role TEXT NOT NULL CHECK (role IN ('user','assistant')),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Phase 2 — RAG documents (vector store)

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flavor_id TEXT NOT NULL,               -- which client this belongs to
    category TEXT NOT NULL,                -- 'manifesto','speech','policy','faq'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768),                 -- nomic-embed-text dimension
    source_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops);
```

### Phase 3 — App content tables

```sql
-- Polls
CREATE TABLE polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flavor_id TEXT NOT NULL,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE poll_votes (
    poll_id UUID REFERENCES polls(id),
    user_id UUID REFERENCES users(id),
    option_index INT NOT NULL,
    voted_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (poll_id, user_id)
);

-- Complaints
CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    category TEXT,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- News / Events (CMS-fed or admin-entered)
CREATE TABLE content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flavor_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('news','event','speech','tweet')),
    title TEXT NOT NULL,
    body TEXT,
    image_url TEXT,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

---

## RAG Implementation Plan

### How It Works

```
User: "What is TVK's policy on drinking water?"
        │
        ▼
1. Embed user message → vector (768 dimensions)
        │
        ▼
2. Search documents table → top 3 most similar chunks
        │
        ▼
3. Build prompt:
   SYSTEM: You are Vijay, CM of Tamil Nadu...
   CONTEXT: [chunk1] [chunk2] [chunk3]
   USER: What is TVK's policy on drinking water?
        │
        ▼
4. Send to gpt-oss:20b-cloud → reply
        │
        ▼
5. Return reply to app
```

### What to Feed the RAG

| Category | Content | Priority |
|---|---|---|
| Manifesto | TVK's 12 ideology points + plans | P0 |
| Speeches | Vijay's key speeches (text) | P0 |
| Policies | State schemes, welfare programs | P1 |
| FAQ | Common citizen questions + answers | P1 |
| News | Recent party announcements | P2 |

### Files to Build

- `services/agent/rag.py` — search function: takes query string, returns top-N document chunks
- `services/agent/ingest.py` — CLI script: reads files from `data/` folder, embeds, stores in DB
- Update `services/agent/agent.py` — call RAG before building the LLM prompt

---

## Phase-by-Phase Build Plan

### ✅ Phase 0 — Done

- Flutter app (13+ screens, all tabs, MVVM)
- Firebase Phone OTP auth
- FastAPI chat agent with Ollama gpt-oss:20b-cloud
- In-memory session store
- Local SharedPreferences persistence
- YouTube integration (live + shorts)
- Fan page / community wall
- Polls, news, profile, settings screens

---

### 🔲 Phase 1 — Backend Foundation (1–2 weeks)

**Goal:** Replace in-memory + SharedPreferences with real DB

Tasks:

1. Add PostgreSQL + pgvector to `docker-compose.yml`
2. Add Redis to `docker-compose.yml`
3. Create all Phase 1 DB tables (`users`, `chat_sessions`, `chat_messages`)
4. Update `agent.py` — read/write chat history from PostgreSQL instead of dict
5. Add Firebase token verification in FastAPI (`firebase-admin` library)
6. Issue our own short-lived JWT after Firebase verification
7. Flutter: send JWT on every request, handle token refresh

**Verification:** Chat history survives backend restart. Multiple users isolated.

---

### 🔲 Phase 2 — RAG (1 week)

**Goal:** AI answers from real TVK documents, not generic knowledge

Tasks:

1. Create `documents` table with pgvector
2. Write `ingest.py` — embed documents using `nomic-embed-text` via Ollama
3. Add TVK manifesto + speeches to `data/` folder
4. Write `rag.py` — cosine similarity search
5. Update `agent.py` — prepend RAG context to every LLM call
6. Test: ask questions about TVK policies, verify grounded answers

**Verification:** Ask "What are TVK's plans for education?" — answer cites real manifesto content.

---

### 🔲 Phase 3 — App Content Backend (1 week)

**Goal:** News, events, polls served from DB instead of hardcoded mock data

Tasks:

1. Create `content_service/` — FastAPI :8002
2. Create `content_items`, `polls`, `poll_votes`, `complaints` tables
3. Admin endpoint to create/update news + events (simple JSON POST, no CMS yet)
4. Flutter: update `ContentService` to call API instead of returning mock data
5. Poll votes stored in DB, user can only vote once

**Verification:** Admin adds a news item via API → it appears in app.

---

### 🔲 Phase 4 — User Profiles + KYC (1 week)

**Goal:** Know who each user is, their constituency, their history

Tasks:

1. Create `user_service/` — FastAPI :8003
2. On first login: create user record linked to Firebase UID
3. Profile screen "Edit" → saves name, constituency, ward to DB
4. Chat sessions linked to authenticated user in DB
5. KYC form (Join TVK screen) → stores member application

**Verification:** User edits profile → logs out → logs back in → profile restored.

---

### 🔲 Phase 5 — Staging Deploy (1 week)

**Goal:** App running on real server, not LAN IP

Tasks:

1. Provision 1× EC2 t3.medium in ap-south-1
2. Install Docker + Docker Compose on EC2
3. Write `docker-compose.prod.yml` with all services
4. Set up RDS PostgreSQL (ap-south-1)
5. Set up ElastiCache Redis
6. Deploy all FastAPI services to EC2
7. Set up Nginx reverse proxy + SSL (Let's Encrypt)
8. Update Flutter `app_config.dart` to use `https://api.tvk.app`
9. TestFlight build for iOS beta testing

**Verification:** Real device connects to prod API. Chat works. Auth works.

---

### 🔲 Phase 6 — Production on ECS Fargate (2 weeks)

**Goal:** Scalable production, ready for 5 crore users

Tasks:

1. Write Terraform for ECS cluster, task definitions, ALB
2. Migrate from EC2 to ECS Fargate
3. Switch LLM from Ollama to AWS Bedrock (Claude Haiku — cheaper, no GPU needed)
4. Set up CloudFront CDN for images/assets
5. Set up Route 53 DNS
6. CI/CD pipeline (GitHub Actions → ECR → ECS deploy)
7. App Store submission (iOS)
8. Google Play submission (Android)
9. Monitoring: CloudWatch + Sentry

---

### 🔲 Phase 7 — Voice (Tamil speech)

**Goal:** Citizen can speak in Tamil, leader replies in voice

Tasks:

1. Integrate Sarvam AI STT — Tamil speech → text
2. Integrate Coqui XTTS — text → Vijay voice clone
3. Flutter: add mic button to chat screen
4. Flutter: play audio reply

---

## Docker Compose — Full Stack (Target)

```yaml
# This is the target docker-compose.yml after Phase 1
version: "3.9"

services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: political_platform
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  agent:
    build: ./services/agent
    ports:
      - "8001:8001"
    environment:
      DATABASE_URL: postgresql://app:${DB_PASSWORD}@postgres:5432/political_platform
      REDIS_URL: redis://redis:6379
      OLLAMA_URL: http://host.docker.internal:11434
      LLM_MODEL: gpt-oss:20b-cloud
      FIREBASE_PROJECT_ID: political-platform-19d77
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      - postgres
      - redis
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  pgdata:
```

---

## Environment Variables (.env — never commit)

```
DB_PASSWORD=<strong-random-password>
JWT_SECRET=<64-char-random-secret>
FIREBASE_PROJECT_ID=political-platform-19d77
OLLAMA_URL=http://localhost:11434
LLM_MODEL=gpt-oss:20b-cloud
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=ap-south-1
YOUTUBE_API_KEY=<key>
```

---

## Cost Estimate (Production — per month)

| Service | Type | Cost/month |
|---|---|---|
| ECS Fargate (3 services × 0.25vCPU/0.5GB) | Compute | ~$30 |
| RDS PostgreSQL db.t3.large Multi-AZ | Database | ~$120 |
| ElastiCache cache.t3.medium | Cache | ~$50 |
| AWS Bedrock Claude Haiku (1M msgs/day) | LLM | ~$150 |
| CloudFront + S3 | CDN | ~$10 |
| ALB | Load balancer | ~$20 |
| **Total** | | **~$380/month** |

> At 50M users with 1 message/day average: Bedrock cost dominates. Can optimize with response caching in Redis.

---

## Instructions for AI Agents Working on This Repo

### Before touching any file

1. Read `CLAUDE.md` (or `AGENTS.md` for Codex) — project rules, changelog
2. Read `TEAM_WORKFLOW.md` — workflow, handoff log
3. Read this file (`ROADMAP.md`) — understand where we are in the plan
4. Check current phase — only build what the current phase requires

### Rules that never change

- Flutter: **MVVM strictly** — screens = UI only, ViewModels = logic, Services = API/DB
- **Never break** chat, auth, navigation, or video — test before and after
- **No black backgrounds** on light-theme screens — use brand gradients or white
- **Never commit** `.env`, secrets, API keys, or service account files
- **Never use real client names** in code — use flavor IDs only (`tn-tvk`, `india-pm`)
- One change at a time — small, reviewable, reversible

### After finishing any task

1. Run `flutter analyze` — must show **0 issues**
2. Add a row to the **Completed Phases** table below
3. Add a row to the changelog in `AGENTS.md` and `CLAUDE.md`
4. Update the **Handoff Log** in `TEAM_WORKFLOW.md`

---

## Completed Phases Log

| Date | Phase | What Was Done | Files Touched |
|---|---|---|---|
| 2026-05-07 to 2026-05-11 | Phase 0 | Full Flutter app (13+ screens), Firebase OTP, FastAPI agent, Ollama gpt-oss:20b-cloud, YouTube integration, Fan Page, Polls, all Figma-exact screens | All mobile + services files |
| 2026-05-11 | Arch doc | Created ROADMAP.md — full architecture from monorepo to prod, RAG plan, DB schema, phase plan, AI agent instructions | ROADMAP.md |
