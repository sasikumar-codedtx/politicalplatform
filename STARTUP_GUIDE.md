# Startup Guide

Everything you need to run the full stack locally.

---

## What Runs Where

| Component | What it is | Port |
|---|---|---|
| PostgreSQL + pgvector | Database | 5432 |
| Agent API | FastAPI backend | 8001 |
| Ollama | Local LLM (llama3.2) | 11434 |
| Flutter app | iOS / Android mobile | — |

---

## Step 1 — Start Docker Desktop

Open Docker Desktop from Applications or:

```bash
open -a Docker
```

Wait for the whale icon in the menu bar to stop animating (steady = ready, ~30 seconds).

---

## Step 2 — Start PostgreSQL + Agent API

From the project root:

```bash
cd /Users/sasikumar/Documents/GitHub/political-platform
docker compose up -d
```

**First run** pulls images and builds the agent container (~30 seconds).  
**Subsequent runs** start in ~5 seconds.

Verify both are healthy:

```bash
docker compose ps
```

Expected output:
```
NAME                       STATUS
political_platform_db      running (healthy)
political_platform_agent   running
```

Quick health check:

```bash
curl http://localhost:8001/health
# → {"status":"ok"}
```

---

## Step 3 — Start Ollama (LLM)

```bash
ollama serve
```

Runs on `http://localhost:11434`. Keep this terminal open or run it in the background.

Make sure the model is pulled (one-time only):

```bash
ollama pull llama3.2
```

Verify Ollama is running:

```bash
curl http://localhost:11434/api/tags
```

---

## Step 4 — Update API URL (if your IP changed)

The Flutter app points to your Mac's LAN IP. Check your current IP:

```bash
ipconfig getifaddr en0
```

If it changed, update this file:

```
mobile/app/lib/config/app_config.dart
```

Line to change:
```dart
static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://192.168.29.126:8001');
```

---

## Step 5 — Run Flutter App

```bash
cd /Users/sasikumar/Documents/GitHub/political-platform/mobile/app
flutter run
```

For iOS specifically:

```bash
flutter run -d <device_id>
```

List available devices:

```bash
flutter devices
```

If pods are out of sync (after adding new packages):

```bash
export LANG=en_US.UTF-8
cd ios
pod install
cd ..
flutter run
```

---

## Stopping Everything

```bash
# Stop Docker containers (data is preserved in pgdata volume)
docker compose down

# Stop Ollama — just Ctrl+C in its terminal
```

To wipe the database and start fresh (destructive):

```bash
docker compose down -v
```

---

## Rebuilding the Agent After Code Changes

If you change Python files in `services/agent/`:

```bash
docker compose up -d --build agent
```

---

## Environment Variables

All config lives in `.env` at the project root. Never commit this file.

```
OLLAMA_URL=http://localhost:11434
LLM_MODEL=llama3.2
APP_ENV=development
DB_PASSWORD=devpassword123
DATABASE_URL=postgresql://app:devpassword123@localhost:5432/political_platform
```

---

## Quick Status Check (all at once)

```bash
# Docker containers
docker compose ps

# Backend API
curl http://localhost:8001/health

# Ollama
curl http://localhost:11434/api/tags

# Active sessions in DB
curl http://localhost:8001/sessions
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `no configuration file provided` | You're not in the project root. Run `cd /Users/sasikumar/Documents/GitHub/political-platform` first |
| `docker.sock: no such file or directory` | Docker Desktop isn't running. `open -a Docker` and wait |
| `zsh: command not found: docker-compose` | Use `docker compose` (space, no hyphen) |
| Rosetta install error | `softwareupdate --install-rosetta --agree-to-license` |
| Flutter can't reach API | Check IP with `ipconfig getifaddr en0` and update `app_config.dart` |
| OTP slow on real device (~5s delay) | APNs not configured yet — reCAPTCHA fallback is expected |
| Pod install fails with encoding error | Run `export LANG=en_US.UTF-8` before `pod install` |
