---
name: multi-agent-coordination
description: Coordinate multiple Claude Code terminals on the same project without collisions. Use when the user wants to run 2+ Claude sessions in parallel on one repo, asks about multi-agent workflows, parallel Claude, terminal coordination, file locks, shared kanban boards, planner/architect roles, or how to avoid two AI sessions editing the same file. Provides interactive setup wizard, file-level lock protocol, shared task board, planner approval gate, configurable git workflow (single-branch or feature-branch), stale-lock detection with TTL, role-tailored terminal intros, and slash commands (/multi-agent-init, /agents-status, /agent-intro, /release-locks).
---

# Multi-Agent Coordination

A reusable system for running multiple Claude Code terminals on the same project safely. Extracted from production use (Etihad CRM), generalized for any stack.

## When to activate

Activate this skill when the user:
- Wants to run 2+ Claude Code sessions in parallel on one repo
- Asks about multi-agent / parallel-Claude / squad workflows
- Mentions file collisions between AI sessions
- Asks for a shared task board / kanban for AI agents
- Wants a planner+developer split (architect terminal vs coder terminals)
- Asks how to do file locking, approval gates, or commit coordination across AI sessions

## The five core mechanics

1. **Terminal roles** — each session has an explicit role: Planner (T4 — reviews, never writes code) or Developer (T1/T2/T3… — implements). See `references/terminal-roles.md`.
2. **File locks** — `active_files.md` is a shared lock registry. Append a line before editing, remove after. Timestamped so stale locks expire. See `references/lock-protocol.md`.
3. **Shared kanban** — `active_tasks.md` has four sections (TODO / AWAITING REVIEW / BLOCKED / DONE). Single source of truth for what each terminal is doing. See `references/lock-protocol.md` (kanban section).
4. **Approval gate** — developers never commit until the planner has reviewed the uncommitted diff and explicitly approved. See `references/approval-gate.md`.
5. **Git workflow** — pick Variant A (per-task feature branches + PR) or Variant B (direct commits to a single integration branch). See `references/git-workflow-variants.md`.

## Scale modes

The system scales by terminal count — pick at setup time:

| Mode    | Terminals | Composition                          |
| ------- | --------- | ------------------------------------ |
| Solo    | 1         | Just task tracking, no locks needed  |
| Pair    | 2         | 1 planner + 1 developer              |
| Squad   | 3–4       | 1 planner + 2–3 developers           |
| Swarm   | 5+        | 1 planner + N developers + extra rules |

## What this skill provides

- **Setup wizard** (`/multi-agent-init`) — interactive; asks the user every setting (mode, TTL, branch names, build/test commands, git variant) and writes a tailored config. Never assumes defaults silently.
- **Terminal intros** (`/agent-intro`) — when a fresh terminal starts, this command reads the saved config + asks which terminal number the session is, then prints a role-tailored intro that includes the lock protocol, kanban rules, commit rules, and any project-specific commands.
- **Status board** (`/agents-status`) — shows the kanban + active locks + stale-lock warnings in one view.
- **Release locks** (`/release-locks`) — clean up locks held by the current terminal (use on session exit / crash recovery).
- **Templates** — kanban template, lock file template, CLAUDE.md section template, role-tailored intros.

## Setup wizard — fast by default (3-5 prompts)

When the user invokes `/multi-agent-init`, the wizard is built to feel fast. Most users finish in 3-5 prompts.

### Flow

1. **Preset** (the only mandatory question) — Solo / Pair / Squad ⭐ / Swarm / Custom. Each preset bakes in sensible defaults (TTL 15min, Variant B, approval gate ON, Conventional Commits) so the user does NOT have to answer those individually.
2. **Auto-detection** — wizard reads `package.json` / `Cargo.toml` / `pyproject.toml` / `Makefile` to propose build + test commands; runs `git symbolic-ref` to propose integration / production branches; uses the directory name for the project name. Presents them in **one** confirmation step: "Use these, customize commands, customize branches, or customize everything?"
3. **Swarm size** — only asked if the preset was Swarm.
4. **Custom mode** — only asked if the preset was Custom. Walks through all 13 individual settings.
5. **Final confirmation** — show the fully resolved config and ask "Confirm and write?"

Presets cover ~95% of cases. Power users pick Custom for full control.

### Preset defaults (NOT asked)

| Setting | Solo | Pair | Squad | Swarm |
|---------|------|------|-------|-------|
| has_planner | false | true | true | true |
| lock_ttl_minutes | n/a | 15 | 15 | 15 |
| stale_lock_policy | n/a | auto-clear | warn | warn |
| git_variant | B | B | B | B |
| approval_gate_enabled | false | true | true | true |
| commit_format | conventional | conventional | conventional | conventional |

### What the wizard writes

- `.multi-agent/config.json` — all final settings (**committed**, not gitignored — team members get the same config on clone)
- `active_tasks.md` — empty kanban (from `templates/active_tasks.md`) — gitignored
- `active_files.md` — empty lock registry (from `templates/active_files.md`) — gitignored (skipped in Solo)
- `CLAUDE.md` — appended with the multi-agent section between BEGIN/END markers, **interpolated** with the user's answers
- `.gitignore` — patched to exclude only `active_tasks.md` and `active_files.md`

Then the wizard **outputs N ready-to-paste intro blocks** — one per terminal — tailored from `templates/intros/`. The user opens N terminals and pastes the matching intro into each.

## Planner intro flow (after setup)

Once `/multi-agent-init` finishes, the Planner terminal (the one that ran setup) outputs:

```
✅ Setup complete. Open N more Claude Code terminals in this project.
Then paste the following into each:

━━━ TERMINAL 1 (Developer A) ━━━
<contents of templates/intros/developer-intro.md, interpolated with config>

━━━ TERMINAL 2 (Developer B) ━━━
<same, with terminal number 2>

…
```

This way the user does not have to explain anything — every terminal gets onboarded automatically.

## Lock protocol (one-paragraph version)

Before editing any file: read `active_files.md`. If the target path is listed by another terminal, wait 30s and recheck. If not listed, append `- <path> → terminal <N> @ <ISO-timestamp>`. Edit. Remove the line immediately when done. Locks older than the configured TTL are stale — any terminal may warn or auto-clear them per project policy. Full details and edge cases: `references/lock-protocol.md`.

## Approval gate (one-paragraph version)

Developers must not run `git add` / `git commit` / `git push` / `gh pr create` until the planner has reviewed the uncommitted diff and the user has relayed an explicit "approved" message. Developers signal readiness by moving the task to `AWAITING REVIEW` in `active_tasks.md` and saying so in chat. Planner verifies via `git diff` + typecheck + test + manual run, then approves or blocks. Exception: pure-docs / planning-file commits and explicit user-authorized hotfixes. Full flow: `references/approval-gate.md`.

## Git workflows (when to pick which)

- **Variant A** (feature branches + PR per task) — better for teams that already use code review tooling, want per-task isolation, and don't mind cross-branch dependency overhead.
- **Variant B** (direct commits to integration branch) — better for solo users + AI assistants where the planner approval gate already plays the role of code review. Simpler, no cross-branch dependency chaos. **Recommended default.**

Details, hotfix flows, and the rationale for Variant B: `references/git-workflow-variants.md`.

## Troubleshooting common issues

Stale locks after a crash, two terminals colliding on a task, planner unable to spawn sub-agents, conflicts during `git pull --rebase`, and what to do when CI goes red mid-coordination — all covered in `references/troubleshooting.md`.

## Files

| Path                                | Purpose                                              |
| ----------------------------------- | ---------------------------------------------------- |
| `references/terminal-roles.md`      | What each role does and what it MAY NOT do           |
| `references/lock-protocol.md`       | Full lock + kanban protocol with edge cases          |
| `references/approval-gate.md`       | Pre-commit review flow and exceptions                |
| `references/git-workflow-variants.md` | Variant A vs B, hotfix flow, release flow          |
| `references/troubleshooting.md`     | Common breakage and recovery recipes                 |
| `templates/active_tasks.md`         | Empty kanban template                                |
| `templates/active_files.md`         | Empty lock-registry template                         |
| `templates/CLAUDE-section.md`       | Block to append to project CLAUDE.md                 |
| `templates/intros/planner-intro.md` | Intro the planner terminal reads on session start    |
| `templates/intros/developer-intro.md` | Intro a developer terminal reads on session start  |
| `templates/intros/solo-intro.md`    | Intro for the lite single-terminal mode              |

## Where things live (global vs per-project)

- **Skill itself** — installed once per machine at `~/.claude/plugins/multi-agent-coordination/`. Available in every project automatically. Re-installing is only needed on new machines.
- **Per-project config** — `.multi-agent/config.json` at the project root. **Committed to git** so collaborators cloning the repo get the same multi-agent settings without re-running the wizard.
- **CLAUDE.md block** — appended to the project's `CLAUDE.md` between BEGIN/END markers. Committed. Auto-loaded by every Claude Code session in that project, so terminals know the rules without explicit `/agent-intro`.
- **Live state** — `active_tasks.md`, `active_files.md` at the project root. **Gitignored.** These represent in-flight kanban + lock state, not durable config.

This means: once a user installs the skill and runs `/multi-agent-init` in a project, that project is permanently configured. Every new terminal session loads CLAUDE.md + reads config.json automatically. No re-install per project.

## Important guardrails

- **Never assume settings the user did not pick or default into via a preset.** Presets bake in defaults transparently; Custom mode asks every question.
- **Never commit on the user's behalf without their relay.** The approval gate exists because automated commits cause more cleanup than they save.
- **Locks are honor-system.** This is a coordination protocol, not OS-level locking. It works because all participants follow it — if a terminal ignores the protocol, no enforcement.
- **Do not edit `active_files.md` / `active_tasks.md` while another terminal holds a lock on them implicitly** — these files are written by every terminal; treat appends as atomic single-line writes and re-read before every operation.
