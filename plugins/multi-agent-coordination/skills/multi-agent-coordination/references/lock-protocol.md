# Lock Protocol & Shared Kanban

Two coordination files live at the repo root and are **gitignored**:

- `active_files.md` — file-level lock registry
- `active_tasks.md` — shared kanban board

Both are append-/edit-heavy and read by every terminal multiple times per task.

## active_files.md — file lock registry

### Line format

```
- <relative/path/from/repo/root> → terminal <N> @ <ISO-8601-timestamp>
```

Example:
```
- frontend/src/views/admin/Dashboard.vue → terminal 1 @ 2026-05-24T14:32:15+05:00
- backend/src/modules/auth/auth.service.ts → terminal 2 @ 2026-05-24T14:35:02+05:00
- frontend/src/i18n/locales/ru.json → terminal 4-pricing-i18n @ 2026-05-24T14:40:00+05:00
```

### Protocol (per file edit)

1. **Read** `active_files.md`.
2. **Check** if the target path is already listed.
   - If listed by another terminal: check the timestamp. If older than the configured TTL (default 15 min), it is stale — proceed per the configured stale-lock policy (auto-clear or warn user). If fresher than TTL: wait 30s, re-read, re-check. Loop until the lock disappears.
   - If listed by **this** terminal: edit directly, no need to re-add.
   - If not listed: continue.
3. **Acquire**: append the line. One line per file. Use the current ISO-8601 timestamp.
4. **Edit** the file (Read + Edit / Write as normal).
5. **Release**: remove **only the line you added** from `active_files.md`. Do not touch other terminals' lines.

### Rules

- Lock per file, not per directory.
- Always release, even if the edit failed or was reverted.
- Batch edits: lock each file before its edit, release each after. Don't hold a stack of locks for minutes.
- Read-only operations (`Read`, `Grep`, `Bash` inspection, `git status`, `git diff`) do NOT need a lock.
- `active_files.md` itself is gitignored — never commit it.
- Sub-agents spawned by the planner lock under a label: `terminal 4-<short-slug>`. Same release rules apply.

### Stale-lock detection

A lock is stale when `(now − timestamp) > configured_TTL`. The TTL is set at `/multi-agent-init` time.

Two policies (also configured at setup):

- **Auto-clear** — any terminal noticing a stale lock removes it and proceeds. Safe default for solo + pair modes.
- **Warn only** — the noticing terminal prints a warning and asks the user before clearing. Safer default for squad / swarm where the lock might still represent live work that crashed mid-edit.

The `/agents-status` command surfaces stale locks. The `scripts/check-stale-locks.sh` script does the same from any shell.

### Recovery: a crashed terminal left locks behind

1. Run `/release-locks` from the recovered terminal — it removes every line whose terminal label matches the current session.
2. Or, in any terminal, run `scripts/check-stale-locks.sh` and either auto-clear or hand-edit.

## active_tasks.md — shared kanban

Single source of truth for what each terminal is doing right now and what's been finished.

### Four sections in order

1. **🟢 IN PROGRESS / TODO** — tasks assigned to a terminal with full brief (files to edit, acceptance criteria, lock list).
2. **🟡 AWAITING REVIEW** — task is implemented + typecheck + tests pass, but NOT yet committed. Waiting for planner review + explicit approval relay before commit / PR.
3. **🟠 BLOCKED / BUGGY / INCOMPLETE** — task started but didn't ship cleanly: half-done, broken build, regression found, waiting on a decision, planner flagged in review. Each entry says **what's wrong** and **what's needed to unblock**.
4. **✅ DONE** — completed tasks (planner-approved + committed + PR opened or merged). Keep brief title + commit hash + date + review marker (`✓` clean, `⚠` with notes).

### Protocol

- **Planner writes new tasks** into TODO with assignee (T1 / T2 / T3) and full file / lock details. Planner picks the assignee by current workload + file ownership (don't assign two tasks touching the same file to different terminals at once).
- **Developer** reads its assigned task, locks files via `active_files.md`, implements, runs typecheck + tests locally, then **moves the task to AWAITING REVIEW** with a short status note (files changed, verify steps already run). Releases all file locks. Tells the user in chat: "<TASK-ID> ready for review."
- **STOP at AWAITING REVIEW.** Do NOT `git add` / `commit` / `push` yet.
- **Planner reviews** the uncommitted diff, runs typecheck / tests / browser smoke test, and outputs the structured review report (see `references/terminal-roles.md`).
- **After user relays approval**, the developer:
  - `git fetch && git pull --rebase <integration-branch>`
  - `git add` specific files
  - `git commit -m "<type>(<scope>): <description>"`
  - `git push origin <integration-branch>` (Variant B) or open PR (Variant A)
  - Move the task to DONE with commit hash.
- **If planner blocks**, move to BLOCKED with "what's wrong + what's needed." Fix → return to AWAITING REVIEW.
- **If a blocker is hit mid-implementation**, move to BLOCKED with a clear note and ping the planner.
- **Always include date** (YYYY-MM-DD) and a short task ID like `S1-A`, `S1-B`, `S2-A` so chat references are unambiguous.
- **Keep entries concise** — file paths, what to do, acceptance criteria. No essays.

### Task brief template (TODO section)

```markdown
### S2-A — <short title> (T1)
**Date:** 2026-05-24
**Files:**
- frontend/src/views/admin/Dashboard.vue (edit)
- frontend/src/services/dashboard.ts (edit)
**Locks needed:** the two files above
**Acceptance:**
- New "Active Users" tile renders with live count from `/api/v1/dashboard/active-users`
- Loading + error states handled
- Unit test added in `dashboard.spec.ts`
**Verify:** `cd frontend && npm run build && npm test`
```

### AWAITING REVIEW entry template

```markdown
### S2-A — <short title> (T1) — ready for review
**Files changed:**
- frontend/src/views/admin/Dashboard.vue: added <Tile> component, wired loading state
- frontend/src/services/dashboard.ts: new getActiveUsers()
**Verified locally:** vue-tsc clean, npm test pass (1 new test green), browser smoke OK
**Skipped / follow-up:** none
```

### DONE entry template

```markdown
### S2-A — <short title> ✓ T1 — 2026-05-24
- Commit: `abc1234`
- Review: clean
```

(`⚠` instead of `✓` if approved with notes.)

## What goes in CLAUDE.md vs. these files

- **CLAUDE.md** — durable rules (role definitions, lock protocol summary, approval gate, git workflow, project-specific conventions). Committed.
- **active_tasks.md** — ephemeral kanban state. Gitignored.
- **active_files.md** — ephemeral lock state. Gitignored.

The setup wizard appends a "Multi-Agent Coordination" block to CLAUDE.md so every terminal session loads the rules automatically.
