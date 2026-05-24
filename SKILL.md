---
name: multi-agent-coordination
description: Coordinate multiple Claude Code terminals on the same project without collisions. Use when the user wants to run 2+ Claude sessions in parallel on one repo, asks about multi-agent workflows, parallel Claude, terminal coordination, file locks, shared kanban boards, planner/architect roles, or how to avoid two AI sessions editing the same file. Provides interactive setup wizard, file-level lock protocol, shared task board, planner approval gate, configurable git workflow (single-branch or feature-branch), stale-lock detection with TTL, role-tailored terminal intros, and slash commands (/multi-agent-init, /agents-status, /agent-intro, /release-locks).
---

# Multi-Agent Coordination

Run multiple Claude Code terminals on one project safely. Battle-tested in production (extracted from a real CRM where 4 Claude sessions ship features in parallel daily).

## Install

### Via skills.sh CLI

```bash
npx skills add RahimjonovBoburjon/multi-agent-coordination
```

Works across Claude Code, OpenAI Codex CLI, Cursor, Gemini CLI, GitHub Copilot, and other agents.

### Via Claude Code plugin marketplace

```
/plugin marketplace add RahimjonovBoburjon/multi-agent-coordination
/plugin install multi-agent-coordination
```

## Quickstart

In any project, run:

```
/multi-agent-coordination:multi-agent-init
```

The wizard asks 3-5 prompts (Solo / Pair / **Squad** / Swarm / Custom presets) and:

1. Writes `.multi-agent/config.json` with your settings
2. Creates `active_tasks.md` (kanban) + `active_files.md` (lock registry)
3. Patches `.gitignore`
4. Appends a coordination block to `CLAUDE.md`
5. Prints ready-to-paste intros for every terminal — paste each into the matching session as the first message

Open N more terminals, paste each intro. They're coordinated.

## Five core mechanics

1. **Terminal roles** — `P` (planner — reviews, never writes code) and `T1`, `T2`, `T3`, … (developers — implement, wait for approval before commit).
2. **File locks** — append `- <path> → T<N> @ <ISO-timestamp>` to `active_files.md` before editing; remove after. Locks older than the configured TTL are stale.
3. **Shared kanban** — `active_tasks.md` with four sections: 🟢 TODO → 🟡 AWAITING REVIEW → 🟠 BLOCKED → ✅ DONE.
4. **Approval gate** — developers stop at AWAITING REVIEW; planner reviews the uncommitted diff and replies `approved <TASK-ID>` or `blocked <TASK-ID>`. Only then does the developer commit.
5. **Git workflow** — pick Variant A (per-task feature branches + PR) or Variant B (direct commits to integration branch — recommended for solo/AI).

## Slash commands

| Command | Purpose |
| --- | --- |
| `/multi-agent-coordination:multi-agent-init` | Interactive setup wizard. Idempotent. |
| `/multi-agent-coordination:agent-intro` | Print current terminal's role intro. |
| `/multi-agent-coordination:agents-status` | Show kanban + active locks + stale-lock warnings. |
| `/multi-agent-coordination:claim-task` | Move TODO task to IN PROGRESS for this terminal + pre-acquire locks. |
| `/multi-agent-coordination:release-locks` | Remove all locks held by this terminal (use on exit / recovery). |

## Where to learn more

The full skill content — references (lock protocol details, approval gate flow, git workflow variants, troubleshooting), templates (kanban, lock registry, CLAUDE.md section, role-tailored intros), and command specs — lives in:

```
plugins/multi-agent-coordination/skills/multi-agent-coordination/
├── SKILL.md                # full skill instructions
├── references/             # deep-dive docs
│   ├── terminal-roles.md
│   ├── lock-protocol.md
│   ├── approval-gate.md
│   ├── git-workflow-variants.md
│   └── troubleshooting.md
└── templates/              # kanban / locks / intros / CLAUDE-section
```

When the skill is invoked, those files are loaded lazily as Claude needs them.

## License

MIT © 2026 Boburjon Rahimjonov · https://github.com/RahimjonovBoburjon/multi-agent-coordination
