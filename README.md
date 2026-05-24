# multi-agent-coordination

> Run **multiple Claude Code terminals on one project** without collisions. File-level locks, shared kanban, planner approval gate. Battle-tested in production — extracted from a real CRM where 4 Claude sessions ship features in parallel every day.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](#install)

---

## What problem does this solve

You open 3 Claude Code terminals to ship faster. Two of them edit the same file. One of them commits broken code. You spend an hour reverting. Sound familiar?

This skill enforces a coordination protocol that has shipped hundreds of tasks in production:

- **File-level locks** (`active_files.md`) — no two terminals edit the same file at once.
- **Shared kanban** (`active_tasks.md`) — every terminal sees what the others are working on.
- **Planner approval gate** — one terminal plans + reviews, never writes code; developers never commit without explicit approval.
- **Stale-lock TTL** — crashed terminals don't deadlock the team.
- **Configurable git workflow** — single integration branch (Variant B, recommended) or feature branches + PR (Variant A).

It scales from **Solo** (1 terminal, lite task tracking) to **Swarm** (5+ terminals, full coordination).

---

## Install

### Option 1 — Claude Code plugin marketplace

```bash
/plugin marketplace add RahimjonovBoburjon/multi-agent-coordination
/plugin install multi-agent-coordination
```

### Option 2 — skills.sh

```bash
npx skills add RahimjonovBoburjon/multi-agent-coordination
```

### Option 3 — manual

Clone the repo, copy `plugins/multi-agent-coordination/skills/multi-agent-coordination/` into `~/.claude/skills/`, and `plugins/multi-agent-coordination/commands/` into `~/.claude/commands/`.

---

## Quickstart

In your project, open a Claude Code terminal:

```
/multi-agent-init
```

The setup wizard is **fast — 3 to 5 prompts** for most users:

1. **Pick a preset** — Solo / Pair / **Squad** ⭐ / Swarm / Custom. Each preset bakes in sensible defaults (15min lock TTL, Variant B git, approval gate ON, Conventional Commits) so you don't answer those one-by-one.
2. **Confirm auto-detected settings** — the wizard reads `package.json` / `Cargo.toml` / etc. to propose build + test commands, and detects your default branch. Approve or customize.
3. *(Swarm only)* Exact terminal count.
4. *(Custom only)* Full 13-question flow if you want total control.

Then it:

1. Writes `.multi-agent/config.json` with your final settings — **committed to git** so the whole team gets the same config.
2. Creates `active_tasks.md` (kanban) and `active_files.md` (lock registry) — these stay gitignored.
3. Appends a "Multi-Agent Coordination" section to `CLAUDE.md`, interpolated with your settings, so every future terminal session loads the rules automatically.
4. **Prints ready-to-paste intros** for every terminal you plan to open — each one role-tailored, with TTL, branches, build commands baked in.

Open N more Claude Code terminals. Paste the matching intro into each. They're now coordinated.

## Where things live (one-time install, per-project setup)

- **Skill** — installed once per machine at `~/.claude/plugins/`. Available in every project on that machine. You only re-install on new machines.
- **`.multi-agent/config.json` + `CLAUDE.md` block** — committed to the project. Team members cloning the repo get the multi-agent rules automatically; they just need the skill installed on their own machine.
- **`active_tasks.md`, `active_files.md`** — gitignored. Live kanban + lock state, not durable config.

You install the skill **once**. You run `/multi-agent-init` **once per project**. Every Claude Code session after that auto-loads the config — no re-setup needed.

---

## How it works (at a glance)

### 1. File locks

Before editing any file, every terminal appends a line to `active_files.md`:

```
- frontend/src/views/admin/Dashboard.vue → terminal 1 @ 2026-05-24T14:32:15+05:00
```

When the edit is done, the line is removed. Other terminals reading the file see the lock and wait. Locks older than the configured TTL are stale — auto-cleared or warned about per project policy.

### 2. Shared kanban

`active_tasks.md` has four columns: **🟢 TODO**, **🟡 AWAITING REVIEW**, **🟠 BLOCKED**, **✅ DONE**. The planner writes new tasks; developers move them between columns.

### 3. Approval gate

Developers run typecheck + tests, move the task to AWAITING REVIEW, and **stop**. The planner reviews the uncommitted diff, runs the build, exercises the feature manually, and replies `approved <TASK-ID>` or `blocked <TASK-ID>: <reason>`. Only then does the developer commit.

### 4. Role-tailored intros

When a new terminal joins (or restarts), run `/agent-intro`. It asks which terminal this is, then prints a tailored intro: planner gets architect responsibilities; developers get implementation rules and project commands.

---

## Slash commands

| Command              | Purpose                                                            |
| -------------------- | ------------------------------------------------------------------ |
| `/multi-agent-init`  | Interactive setup wizard. Run once per project (re-runnable).      |
| `/agent-intro`       | Print the current terminal's role intro. Run at session start.     |
| `/agents-status`     | Show kanban + active locks + stale-lock warnings.                  |
| `/claim-task`        | Move a TODO task to IN PROGRESS for this terminal + pre-acquire locks. |
| `/release-locks`     | Remove all locks held by this terminal (use on exit / recovery).   |

---

## Modes

| Mode    | Terminals | Composition                                                          |
| ------- | --------- | -------------------------------------------------------------------- |
| Solo    | 1         | Lite task tracking. No locks. No approval gate.                      |
| Pair    | 2         | 1 planner + 1 developer. Full protocol.                              |
| Squad   | 3–4       | 1 planner + 2–3 developers. Recommended for active projects.         |
| Swarm   | 5+        | 1 planner + N developers. Extra discipline on file lock granularity. |

---

## Where this comes from

The protocol was developed for **Etihad CRM**, a production NestJS + Vue + Postgres system, where four Claude Code terminals (T1, T2, T3 developers + P planner) ship features in parallel every day. It survived:

- Multi-week sprints with concurrent feature work.
- Cross-task file dependencies (the reason we picked Variant B over feature branches — explained in `references/git-workflow-variants.md`).
- Real crashes mid-edit (the reason for TTL + stale-lock detection).
- A retired Variant A workflow we kept the lessons from but dropped the ceremony of.

What's in this skill is the generic, project-agnostic core. The project-specific parts (Vue conventions, brand colors, NestJS modules) are deliberately not included — your `CLAUDE.md` handles those.

---

## What this is NOT

- **Not OS-level locking.** This is a coordination protocol enforced by all participants reading the same files. If a terminal ignores the protocol, no enforcement.
- **Not a replacement for git.** It complements git; it doesn't replace branches, merges, or history.
- **Not magic.** You still need a planner who reads diffs and runs the app. The skill structures the work; humans + AI do the work.

---

## Roadmap

- [ ] **Pre-tool hook** that auto-locks before any `Edit` / `Write` call (zero-friction enforcement, opt-in).
- [ ] **Terminal-number auto-detect** from Claude Code session ID (skip the "which terminal am I?" question).
- [ ] **Status TUI** — `npx multi-agent-status` for a real-time terminal dashboard.
- [ ] **Cross-IDE bridge** — work alongside Cursor / Codex sessions, not just Claude Code.
- [ ] **Hook templates** — auto-update kanban on commit; notify on stale locks.

---

## Contributing

PRs welcome. Open an issue first for protocol changes — they ripple through every reference doc, template, and intro. For docs / typo / minor improvements, just open a PR.

---

## License

[MIT](LICENSE) © 2026 Boburjon Rahimjonov

---

## Star this if it helped

If running parallel Claude terminals saved you time, a star helps others find it. Thanks!
