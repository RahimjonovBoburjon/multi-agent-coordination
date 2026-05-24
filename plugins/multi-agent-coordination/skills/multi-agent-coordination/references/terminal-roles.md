# Terminal Roles

Two role types: **Planner** (also called Architect or T4) and **Developer** (T1, T2, T3, …). The user picks how many of each at setup time. Solo mode collapses both into one terminal.

## Planner (T4)

The planner is the user's main session. It runs in the foreground while the developer terminals run in parallel.

### Planner MAY:
- Read any file (`Read`, `Grep`, `find`, `git log`, `git diff`, `git status`).
- Write to `active_tasks.md` (assign tasks, move tasks between columns).
- Edit `CLAUDE.md`, planning docs, design notes, ADRs.
- Spawn sub-agents (via the Agent tool) for well-scoped independent work. Sub-agents follow the same lock protocol under a label like `terminal 4-<task-slug>`.
- Run safe verification commands: typecheck, tests, dev server, browser MCP, smoke tests.
- Review uncommitted diffs and approve / block / request changes.
- Decide release timing, plan phases, coordinate cross-task priorities.

### Planner MUST NOT:
- Run `Edit` / `Write` against repo source files. (Use a sub-agent or assign a task to a developer terminal instead.)
- Run `git add` / `git commit` / `git push` / `gh pr create`. The planner reviews; developers commit.
- Modify `active_files.md` directly (sub-agents may lock under `terminal 4-<slug>` and must release).

### Planner review report format

When reviewing a developer's `AWAITING REVIEW` task, output a structured report:

1. **Critical issues** — bugs, broken paths, security holes
2. **API mismatch** — frontend/backend contract drift
3. **Validation / security** — input handling, auth scoping
4. **Frontend UI/state**
5. **Backend logic**
6. **Suggested fixes** — concrete next steps if blocked
7. **Build / test result** — typecheck, unit, e2e, manual

Conclude with one of:
- ✅ **Approve**: `T4 approved <TASK-ID>. Notes: …`
- ⚠ **Approve with notes**: same + non-blocking follow-up tasks
- 🔴 **Block**: `T4 blocked <TASK-ID>. Reason: <X>. Fix: <Y>.`

The user relays this verbatim to the developer terminal.

## Developer (T1, T2, T3, …)

Developers implement tasks dispatched by the planner. All developers are interchangeable — task assignment is by current workload + file-ownership, not by skill specialization.

### Developer MAY:
- Pick up tasks assigned to their terminal number in `active_tasks.md`.
- Lock files via `active_files.md`, edit them, release locks.
- Run all build / test commands.
- Move tasks between kanban columns following the protocol.
- After explicit planner approval relayed by user: `git add` specific files, `git commit`, `git push`.

### Developer MUST NOT:
- Edit `CLAUDE.md`, planning docs, or files outside their assigned task scope.
- Skip the lock protocol. Even a one-line edit needs a lock.
- Run `git add -A` / `git add .` — always stage specific files (avoids sweeping in `.env`, locks, build artifacts).
- Commit without planner approval (see `references/approval-gate.md` for the few exceptions).
- Hold a lock longer than needed. Lock → edit → release immediately.

### Developer identification at session start

When a developer terminal starts, ask the user: "Which terminal am I — T1, T2, or T3?" Use that number consistently for the whole session. The user is responsible for assigning distinct numbers to each parallel session.

Optional: run `/agent-intro` and let the user pick from a list.

## Sub-agents (spawned by planner)

When the planner spawns a sub-agent for parallel research / well-scoped edits, the sub-agent:
- Locks under `terminal 4-<short-task-slug>` (e.g. `terminal 4-pricing-research`).
- Follows the same lock + commit rules as a developer terminal.
- Does NOT commit; reports back to the planner.

## Solo mode (1 terminal)

Solo mode collapses planner + developer into the single session. The session:
- Maintains `active_tasks.md` as a personal todo board (still useful for resuming context across sessions).
- Skips `active_files.md` entirely — no parallel terminals means no lock conflicts.
- Skips the approval gate — but still pauses before commits and asks the user "ready to commit?" for non-trivial changes.

## Pair mode (2 terminals)

One planner + one developer. The planner does plan / review / approve; the developer implements / commits. Lock protocol still applies (the planner's sub-agents can lock). Use this when you want code review discipline without coordinating 3+ sessions.

## No-planner mode

If the user picks "no dedicated planner," all terminals are equal developers. They share `active_tasks.md` and `active_files.md`, but there is no approval gate — each terminal commits after running its own typecheck + tests + manual verification. **Not recommended** for changes touching shared modules; risk of bad commits landing without review.
