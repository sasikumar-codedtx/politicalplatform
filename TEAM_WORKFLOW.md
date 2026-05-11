# Team Workflow

> Shared working agreement for Codex and Claude.
> Read order: `CLAUDE.md` (or `AGENTS.md`) → this file → `ROADMAP.md`
> `ROADMAP.md` has the full architecture, phase plan, and DB schema. Read it every session.

---

## Purpose

This file exists so both assistants work the same way, leave a clear trail, and do not confuse each other.

---

## Mandatory Rules

### 1. Understand before editing
- Read the relevant files first.
- Summarize what you understood before making substantial changes.
- Do not guess architecture or behavior.

### 2. One focused change at a time
- Keep each session scoped to one bug fix, feature, review task, or cleanup.
- Do not mix refactor + feature work unless the task truly requires both.

### 3. Always record the reason
- For every code change, note why it was needed.
- The reason must be written in the handoff log in this file.
- If the change fixes a bug, mention the bug or risk clearly.

### 4. Test after every code change
- Run the most relevant verification for the files touched.
- Examples: `flutter analyze`, focused manual flow check, backend smoke test.
- Record what was tested in the handoff log.
- If something could not be tested, write that clearly.

### 5. Respect MVVM boundaries
- `screens/` are for UI only.
- Business logic belongs in `viewmodels/`.
- API, storage, Firebase, and persistence belong in `services/`.
- Models stay as pure data objects.
- If a screen already contains old logic, do not spread that pattern further.

### 6. Protect working features
- Before changing a working area, understand what already works.
- After changing it, verify it still works.
- Never silently break login, chat, navigation, persistence, or video flows.

### 7. Keep design intentional
- Follow the established Figma-inspired visual quality.
- Do not default to black backgrounds just because older Figma-exact screens used them.
- Prefer brand-led surfaces, gradients, off-whites, or theme tokens when a black background is not necessary.
- Use hardcoded black only when the specific screen truly requires it, like media playback or overlays.

### 8. Prefer tokens over scattered hardcoded colors
- Reuse `AppConfig` and theme values where possible.
- If adding a new reusable color, promote it into shared config/theme instead of repeating literals across screens.

### 9. Do not hide unfinished work
- If there are assumptions, blockers, or follow-ups, write them in the handoff log.
- Leave the next assistant enough context to continue immediately.

### 10. Update project history too
- After a meaningful session, add a row to the changelog in `AGENTS.md`.
- Keep the summary short and factual.

---

## Session Workflow

### Before coding
- Read the relevant files.
- Check for existing local changes and avoid overwriting them.
- State what you understood and what you plan to change.

### While coding
- Keep edits small and reversible.
- Preserve existing behavior unless the task asks for a behavior change.
- Avoid introducing new patterns that violate MVVM.

### After coding
- Run verification.
- Update the handoff log below.
- Update `AGENTS.md` changelog.
- If `CLAUDE.md` mirrors `AGENTS.md`, keep shared workflow references aligned.

---

## Handoff Log

| Date | Change | Reason | Verification | Files |
|---|---|---|---|---|
| 2026-05-11 | Added shared Codex/Claude workflow file and linked both instruction docs to it | Repo had duplicated agent docs but no single shared execution + handoff process | Read repo docs and core app/backend files; ran `flutter analyze` | TEAM_WORKFLOW.md, AGENTS.md, CLAUDE.md |
| 2026-05-11 | Fixed Firebase OTP setup drift in app code by disabling forced simulator test-auth by default and aligning iOS bundle ID case in Firebase options | Real OTP was being blocked on iOS simulator by always enabling Firebase test-phone mode; iOS Firebase config also had bundle ID case mismatch | Code inspection; `flutter analyze` | mobile/app/lib/screens/phone_login_screen.dart, mobile/app/lib/firebase_options.dart, TEAM_WORKFLOW.md, AGENTS.md |
| 2026-05-11 | Reworked home hero section against Figma node `948:1148` while keeping the page light instead of restoring a dark theme | User asked to match the Figma dashboard hero more closely but preserve a white/light visual direction | Figma design context + screenshot for node `948:1148`; `flutter analyze` | mobile/app/lib/screens/home_screen.dart, TEAM_WORKFLOW.md, AGENTS.md |
| 2026-05-11 | Fixed home_screen compile error + added _SocialJusticeSection (5 ideology leaders PageView) | Orphaned brackets from prior edit caused compile failure; Social Justice section was referenced but never written | `flutter analyze` — 0 issues | home_screen.dart |
| 2026-05-11 | Created ROADMAP.md with full architecture, DB schema, RAG plan, 7-phase plan, prod hosting on AWS ECS | User requested full plan from monorepo to production, including RAG training for AI chatbot | File created, all agent instruction files updated to reference it | ROADMAP.md, CLAUDE.md, AGENTS.md, TEAM_WORKFLOW.md |
