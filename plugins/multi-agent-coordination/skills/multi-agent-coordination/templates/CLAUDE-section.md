<!--MAC-BLOCK:BEGIN-->

## 🚨 Multi-Agent Coordination

This project runs **{{TERMINAL_COUNT}}** Claude Code terminals in parallel. Coordination is enforced by three artifacts at the repo root: `active_tasks.md` (kanban), `active_files.md` (file locks), and `.multi-agent/config.json` (settings). The kanban + lock files are gitignored (live state); the config is committed so team members get the same settings on clone.

### Terminal roles

{{ROLES_TABLE}}

If unsure which terminal you are at session start, run `/agent-intro` or ask the user.

### File-lock protocol (mandatory before every edit)

Before editing **any** file:

1. Read `active_files.md`.
2. If the target path is listed by another terminal and the timestamp is fresher than **{{LOCK_TTL_MINUTES}} minutes**, wait 30s and re-check. Loop until the lock disappears.
3. If listed by another terminal but older than TTL: it's stale — per project policy ({{STALE_LOCK_POLICY}}).
4. If not listed: append `- <path> → T<N> @ <ISO-timestamp>` (developers) or `- <path> → P @ <ISO-timestamp>` (planner) and proceed.
5. Edit.
6. Remove your line from `active_files.md` immediately when done.

Read-only operations (`Read`, `Grep`, `git status`, `git diff`) do NOT need a lock.

### Shared kanban (`active_tasks.md`)

Four sections in order: 🟢 IN PROGRESS / TODO → 🟡 AWAITING REVIEW → 🟠 BLOCKED → ✅ DONE.

- **Planner** writes new tasks into TODO with full file lists, acceptance criteria, and an assignee (T1 / T2 / …).
- **Developer** picks up the task, locks files, implements, runs verification, moves the task to AWAITING REVIEW with a status note.
- **STOP** at AWAITING REVIEW. Do NOT commit until the user relays planner approval.
- After approval: pull-rebase → `git add` specific files → commit → push → move to DONE with commit hash.

### Approval gate

{{APPROVAL_GATE_BLOCK}}

### Git workflow — {{GIT_VARIANT_NAME}}

{{GIT_WORKFLOW_BLOCK}}

### Project verification commands

- **Typecheck / build:** `{{BUILD_COMMAND}}`
- **Tests:** `{{TEST_COMMAND}}`

Run both before moving any task to AWAITING REVIEW.

### Commit format

{{COMMIT_FORMAT_BLOCK}}

### Reference

Full coordination protocol: load the `multi-agent-coordination` skill or read its references directly (`lock-protocol.md`, `approval-gate.md`, `git-workflow-variants.md`, `troubleshooting.md`).
<!--MAC-BLOCK:END-->
