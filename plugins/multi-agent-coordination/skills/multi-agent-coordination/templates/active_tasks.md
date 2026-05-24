# Active Tasks — Shared Kanban

> This file is the single source of truth for what each terminal is doing right now. It is **gitignored** — never commit it.

Task ID convention: `S<sprint>-<letter>` (e.g. `S1-A`, `S1-B`, `S2-A`). Date format: `YYYY-MM-DD`. Review markers: `✓` clean, `⚠` with notes.

---

## 🟢 IN PROGRESS / TODO

_(Planner writes new tasks here with full briefs and an assignee. Empty = nothing pending.)_

<!-- Example:
### S1-A — Add Active Users tile to admin dashboard (T1)
**Date:** 2026-05-24
**Files:**
- frontend/src/views/admin/Dashboard.vue (edit)
- frontend/src/services/dashboard.ts (edit)
**Locks needed:** the two files above
**Acceptance:**
- New <Tile> renders with live count from `/api/v1/dashboard/active-users`
- Loading + error states handled
- Unit test in `dashboard.spec.ts`
**Verify:** `cd frontend && npm run build && npm test`
-->

---

## 🟡 AWAITING REVIEW

_(Developer moves task here when work is done locally. Planner reviews. Do NOT commit yet.)_

<!-- Example:
### S1-A — Active Users tile (T1) — ready for review
**Files changed:**
- frontend/src/views/admin/Dashboard.vue: added <Tile>, wired loading state
- frontend/src/services/dashboard.ts: new getActiveUsers()
**Verified locally:** vue-tsc clean, npm test green (1 new test), browser smoke OK
**Skipped / follow-up:** none
-->

---

## 🟠 BLOCKED / BUGGY / INCOMPLETE

_(Tasks that started but didn't ship cleanly. Each entry says what's wrong and what's needed to unblock.)_

<!-- Example:
### S0-C — Telegram webhook retry (T2) — BLOCKED 2026-05-24
**What's wrong:** Bull queue worker not reconnecting after Redis restart.
**What's needed:** decision — wrap with auto-reconnect lib, or migrate to BullMQ?
-->

---

## ✅ DONE

_(Completed + reviewed + committed. Brief title + commit hash + date + review marker.)_

<!-- Example:
### S0-B — JWT secret validation ✓ T1 — 2026-05-23
- Commit: `abc1234`
- Review: clean

### S0-A — Pino logging setup ⚠ T2 — 2026-05-23
- Commit: `def5678`
- Review: notes — follow-up to redact extra header fields (filed as S0-D)
-->
